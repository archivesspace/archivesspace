module AuthHelpers

  # `parent_session` links a PUI session back to the staff session it was
  # handed off from, so that ending either ends both -- including any sibling
  # PUI sessions handed off from the same staff session, which the request
  # middleware invalidates once their parent is gone.  Only the parent's digest
  # is stored; see Session.digest.
  def create_session_for(username, expiring_session, pui_only: false, parent_session: nil)
    session = Session.new
    session[:user] = username
    session[:login_time] = Time.now
    session[:expirable] = expiring_session
    session[:pui_only] = pui_only
    session[:parent_session] = Session.digest(parent_session) if parent_session
    session.save

    session
  end

end
