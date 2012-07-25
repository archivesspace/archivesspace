class SessionController < ApplicationController
  def login    
    response = User.login(params[:username], params[:password])

    if (response.has_key?("session"))
      session[:session] = response["session"]
      session[:user] = params[:username]
    end
    render :json=>response
  end
  
  def logout
    reset_session
    redirect_to :root
  end
end
