class SessionController < ApplicationController

  set_access_control  :public => [:login, :logout, :check_session, :has_session, :login_inline],
                      "become_user" => [:select_user, :become_user]


  def login
    backend_session = User.login(params[:username], params[:password])

    if backend_session
      User.establish_session(self, backend_session, params[:username])
    end

    load_repository_list

    render :json => {:session => backend_session, :csrf_token => form_authenticity_token}
  end


  def login_inline
    render_aspace_partial :partial => "shared/modal", :locals => {:title => I18n.t("session.inline_login_title"), :partial => "shared/login", :id => "inlineLoginModal"}
  end


  def select_user
  end


  def become_user
    if User.become_user(self, params[:username])
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

    if session[:session] && params[:uri]
      render json: user_can_edit?(params)
    else
      render json: false
    end
  end


  def has_session
    render :json => {:has_session => !session[:user].nil?}
  end

  private

  def user_can_edit?(params)

    record_info = JSONModel.parse_reference(params[:uri])

    case record_info[:type]
    when 'accession'
      user_can?('update_accession_record', params[:repository])
    when 'resource', 'archival_object'
      user_can?('update_resource_record', params[:repository])
    when 'digital_object', 'digital_object_component'
      user_can?('update_digital_object_record', params[:repository])
    when /^agent/
      user_can?('update_agent_record')
    when 'subject'
      user_can?('update_subject_record')
    end
  end
end
