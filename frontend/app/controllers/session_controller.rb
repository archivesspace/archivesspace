class SessionController < ApplicationController

  set_access_control  :public => [:login, :logout],
                      "become_user" => [:select_user, :become_user]


  def login
    backend_session = User.login(params[:username], params[:password])

    if backend_session
      User.establish_session(session, backend_session, params[:username])
    end

    load_repository_list

    render :json => {:session => backend_session}
  end


  def select_user
  end


  def become_user
    if User.become_user(session, params[:username])
      flash[:success] = I18n.t("become-user.success")
      redirect_to :controller => :welcome, :action => :index
    else
      flash[:error] = I18n.t("become-user.failed")
      redirect_to :controller => :session, :action => :select_user
    end
  end


  def logout
    reset_session
    redirect_to :root
  end
end
