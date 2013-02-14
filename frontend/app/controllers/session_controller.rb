class SessionController < ApplicationController
  skip_before_filter :unauthorised_access

  def login
    backend_session = User.login(params[:username], params[:password])

    if backend_session
      User.establish_session(session, backend_session, params[:username])
    end

    # load the repo into the user's session again 
    # N.B it may not be the repo the user had last selected (if session expired/lost)!!
    # NEED TO FIX BY RESTORING LAST SELECTED REPO FROM ELSEWHERE
    load_repository_list

    render :json => {:session => backend_session}
  end


  def logout
    reset_session
    redirect_to :root
  end
end
