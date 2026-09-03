module AuthHelpers

  def create_session_for(username, expiring_session, pui_only: false)
    session = Session.new
    session[:user] = username
    session[:login_time] = Time.now
    session[:expirable] = expiring_session
    session[:pui_only] = pui_only
    session.save

    session
  end

end
