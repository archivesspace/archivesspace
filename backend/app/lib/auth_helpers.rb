module AuthHelpers

  def create_session_for(username)
    username = username.downcase

    session = Session.new
    session[:user] = params[:username]
    session[:login_time] = Time.now
    session.save

    session
  end

end
