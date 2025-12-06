class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    render 'shared/login'
  end

  def login
    response = archivesspace.do_login(params[:user_name], params[:password])

    if response
      session[:session] = response['session']
      session[:username] = response['user']['username']
      session[:pui_username] = response['user']['username']
      redirect_to ('/')
    else
      flash.now[:alert] = "Invalid."
      raise LoginFailedException.new("#{response}")
      redirect_to ('/')
    end
  end

  def logout
    uri = URI("#{AppConfig[:backend_url]}/logout")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['X-ArchivesSpace-Session'] = session[:session]
    response = http.request(request)
    reset_session
    redirect_to ('/'), notice: "Logged out successfully."
  end
end
