class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    render 'shared/login'
  end

  def login
    uri = URI("#{AppConfig[:backend_url]}/users/#{params[:user_name]}/login")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(
      password: params[:password],
      pui: true,
      expiring: true
    )

    response = http.request(request)

    parsed_body = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    if response.code == '200' && parsed_body
      session[:session] = parsed_body['session']
      session[:username] = parsed_body['user']['username']
      session[:pui_username] = parsed_body['user']['username']
      redirect_to '/'
    elsif response.code == '403'
      flash.now[:error] = "User `#{params[:user_name]}` does not have permission to view the PUI."
      render 'shared/login'
    else
      flash.now[:error] = "Login failed. Please check your username and password."
      render 'shared/login'
    end
  end

  def staff_handoff
    return head :forbidden unless AppConfig[:pui_require_authentication]

    uri = URI("#{AppConfig[:backend_url]}/users/current-user")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request['X-ArchivesSpace-Session'] = params[:session]

    response = http.request(request)
    parsed_body = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    if response.code == '200' && parsed_body && parsed_body['is_pui_viewer']
      session[:session] = params[:session]
      session[:username] = parsed_body['username']
      session[:pui_username] = parsed_body['username']
      render json: { success: true }
    else
      render json: { success: false }, status: 403
    end
  end

  def logout
    if AppConfig[:pui_require_authentication]
      if AppConfig.has_key?(:frontend_proxy_url)
        uri = URI("#{AppConfig[:frontend_proxy_url]}/logout_pui_session")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri)
        request['X-ArchivesSpace-Session'] = session[:session]
        http.request(request)
      end

      uri = URI("#{AppConfig[:backend_url]}/logout")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['X-ArchivesSpace-Session'] = session[:session]
      http.request(request)
    end

    reset_session
    redirect_to '/', notice: "Logged out successfully."
  end

  def logout_staff_session
    return head :forbidden unless AppConfig[:pui_require_authentication]
    reset_session
    render json: { success: true }
  end
end
