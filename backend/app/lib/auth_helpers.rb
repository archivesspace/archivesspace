module AuthHelpers

  def create_session_for(username, expiring_session)
    session = Session.new
    session[:user] = username
    session[:login_time] = Time.now
    session[:expirable] = expiring_session
    session.save

    session
  end

end
