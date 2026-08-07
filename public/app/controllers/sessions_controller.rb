class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'login'

  def show
    return head :forbidden unless AppConfig[:pui_require_authentication]
    return redirect_to('/') if pui_auth_status == :ok

    render 'shared/login'
  end

  def login
    return head :forbidden unless AppConfig[:pui_require_authentication]

    response = JSONModel::HTTP.post_form("/users/#{params[:user_name]}/login",
                                         :password => params[:password],
                                         :pui => true,
                                         :expiring => true)

    parsed_body = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    if response.code == '200' && parsed_body
      session[:session] = parsed_body['session']
      session[:pui_username] = parsed_body['user']['username']
      redirect_to '/'
    elsif response.code == '403'
      flash.now[:error] = I18n.t('login.pui_permission_denied', username: params[:user_name])
      render 'shared/login'
    else
      flash.now[:error] = I18n.t('login.login_failed')
      render 'shared/login'
    end
  rescue StandardError => e
    Rails.logger.error("SessionsController#login: could not reach the backend (#{e.class}: #{e.message})")
    Rails.logger.error("Stacktrace:\n%s" % [e.backtrace.join("\n")])
    flash.now[:error] = I18n.t('login.login_failed')
    render 'shared/login'
  end

  def staff_handoff
    return head :forbidden unless AppConfig[:pui_require_authentication]

    parsed_body = get_json_as_backend_session('/users/current-user', params[:session])

    if parsed_body['is_pui_viewer']
      session[:session] = params[:session]
      session[:pui_username] = parsed_body['username']
      render json: { success: true }
    else
      render json: { success: false }, status: 403
    end
  rescue StandardError => e
    Rails.logger.error("SessionsController#staff_handoff: could not verify the session with the backend (#{e.class}: #{e.message})")
    Rails.logger.error("Stacktrace:\n%s" % [e.backtrace.join("\n")])
    render json: { success: false }, status: 403
  end

  def logout
    if AppConfig[:pui_require_authentication] && session[:session].present?
      begin
        with_backend_session(session[:session]) { JSONModel::HTTP.post_form('/logout') }
      rescue StandardError => e
        Rails.logger.error("SessionsController#logout: could not reach the backend (#{e.class}: #{e.message})")
        Rails.logger.error("Stacktrace:\n%s" % [e.backtrace.join("\n")])
      end
    end

    reset_session
    redirect_to '/', notice: "Logged out successfully."
  end
end
