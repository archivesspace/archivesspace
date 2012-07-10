module AuthHelpers

  def create_session_for(username)
    session = Session.new
    session[:user] = params[:username]
    session[:login_time] = Time.now
    session.save

    session
  end

end
