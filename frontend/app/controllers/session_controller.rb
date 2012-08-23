class SessionController < ApplicationController

  def login
    backend_session = User.login(params[:username], params[:password])

    if backend_session
      User.establish_session(session, backend_session, params[:username])
    end

    render :json => {:session => backend_session}
  end


  def logout
    reset_session
    redirect_to :root
  end
end
