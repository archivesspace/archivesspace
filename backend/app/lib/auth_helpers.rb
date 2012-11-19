module AuthHelpers

  def create_session_for(username, expiring_session)
    username = username.downcase

    session = Session.new
    session[:user] = params[:username]
    session[:login_time] = Time.now
    session[:expirable] = expiring_session
    session.save

    session
  end

end
