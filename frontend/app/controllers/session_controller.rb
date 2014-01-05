class SessionController < ApplicationController

  set_access_control  :public => [:login, :logout, :check_session],
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


  # let a trusted app (i.e., public catalog) know if a user 
  # should see links back to this editing interface
  def check_session
    response.headers['Access-Control-Allow-Origin'] = AppConfig[:public_proxy_url]
    response.headers['Access-Control-Allow-Credentials'] = 'true'

    if session[:session] && params[:record_type] 
      render json: user_can_edit?(params)
    else
      render json: false
    end
  end

  private

  def user_can_edit?(params)
    case params[:record_type]
    when 'accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'
      user_can?('update_archival_record', params[:repository])
    when /^agent/
      user_can?('update_agent_record')
    when 'subject'
      user_can?('update_subject_record')
    end
  end
end
