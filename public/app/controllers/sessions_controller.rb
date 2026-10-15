class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'login'

  def show
    return head :forbidden unless AppConfig[:pui_require_authentication]
    return redirect_to(root_path) if pui_auth_status == :ok

    @skip_pui_autocheck = skip_pui_autocheck?
    render 'shared/login'
  end

  def login
    return head :forbidden unless AppConfig[:pui_require_authentication]

    if login_throttled?(params[:user_name])
      flash.now[:error] = I18n.t('login.too_many_attempts')
      return render 'shared/login', status: :too_many_requests
    end

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
      reset_login_failures(params[:user_name])
      session[:session] = parsed_body['session']
      session[:pui_username] = parsed_body['user']['username']
      redirect_to root_path
    elsif response.code == '403' && parsed_body && parsed_body['error'] == 'User does not have permission to view the PUI'
      flash.now[:error] = I18n.t('login.pui_permission_denied', username: params[:user_name])
      render 'shared/login'
    else
      record_login_failure(params[:user_name]) if response.code == '403'
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
    session[:skip_pui_autocheck] = true
    redirect_to root_path, notice: "Logged out successfully."
  end

  private

  # Failed login limits per username and per client IP.
  # nil, false, 0 or text in a setting turns that limit off.
  def login_throttle_period
    AppConfig[:pui_login_throttle_period].to_s.to_i
  end

  def login_username_key(user_name)
    "pui_login:#{user_name.to_s.strip.downcase}"
  end

  # Each Fail2Ban key with its failure limit, for the limits that are on.
  def login_failure_limits(user_name)
    return {} unless login_throttle_period > 0

    {
      login_username_key(user_name) => AppConfig[:pui_login_throttle_limit].to_s.to_i,
      "pui_login_ip:#{request.remote_ip}" => AppConfig[:pui_login_ip_throttle_limit].to_s.to_i
    }.select { |_key, limit| limit > 0 }
  end

  def login_throttled?(user_name)
    login_failure_limits(user_name).keys.any? { |key| Rack::Attack::Fail2Ban.banned?(key) }
  end

  def record_login_failure(user_name)
    login_failure_limits(user_name).each do |key, limit|
      Rack::Attack::Fail2Ban.filter(key, maxretry: limit, findtime: login_throttle_period, bantime: login_throttle_period) { true }
    end
  end

  # Reset only the username count. If a successful login reset the IP count, an attacker
  # with any valid account could log in to it between guesses and never reach the IP limit.
  def reset_login_failures(user_name)
    return unless login_failure_limits(user_name).key?(login_username_key(user_name))

    Rack::Attack::Fail2Ban.reset(login_username_key(user_name), findtime: login_throttle_period)
  end
end
