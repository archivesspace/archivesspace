class SessionController < ApplicationController

  set_access_control  :public => [:login, :token_login, :logout, :check_session, :has_session, :login_inline],
                      "become_user" => [:select_user, :become_user]


  def login
    if login_throttled?(params[:username])
      return render :json => {:session => nil, :csrf_token => form_authenticity_token}, :status => :too_many_requests
    end

    backend_response = User.login_response(params[:username], params[:password])
    backend_session = backend_response.code == '200' ? ASUtils.json_parse(backend_response.body) : nil

    if backend_session
      reset_login_failures(params[:username])
      User.establish_session(self, backend_session, params[:username])
    elsif backend_response.code == '403'
      record_login_failure(params[:username])
    end

    load_repository_list

    render :json => {:session => backend_session, :csrf_token => form_authenticity_token}
  end


  def login_inline
    render_aspace_partial :partial => "shared/modal", :locals => {:title => t("session.inline_login_title"), :partial => "shared/login", :id => "inlineLoginModal", :klass => "inline-login-modal"}
  end


  def select_user
  end


  def become_user
    if User.become_user(self, params[:username])
      flash[:success] = t("become-user.success")
      redirect_to :controller => :welcome, :action => :index
    else
      flash[:error] = t("become-user.failed")
      redirect_to :controller => :session, :action => :select_user
    end
  end


  def logout
    User.logout

    reset_session
    redirect_to :root
  end


  # let a trusted app (i.e., public catalog) know whether a user should
  # either 1. see links back to the SUI, or 2. (if PUI authentication is on)
  # be handed off into a PUI session. Gated by the presence/absence of a
  # record :uri.
  def check_session
    set_pui_cors_headers

    if session[:session].blank?
      render json: { can_access: false, mode: nil }
      return
    end

    if params[:uri]
      render json: check_user_access(params)
    elsif !AppConfig[:pui_require_authentication]
      render json: { can_access: false, mode: nil }
    elsif user_can_view_pui?
      render json: pui_handoff_response
    else
      render json: { view_pui: false }
    end
  end


  def has_session
    render :json => {:has_session => !session[:user].nil?}
  end


  def token_login
    backend_session = User.token_login(params[:username], params[:token])
    if backend_session
      # this can't prevent a determined user from using a token-acquired
      # session to do things they could do with a regular login token, but it should
      # suffice to make a typical user reset password and log back in.
      backend_session['user']['permissions'] = {}
      User.establish_session(self, backend_session, params[:username])
    else
      flash[:error] = I18n.t('login.password_update_error')
    end

    redirect_to :controller => :users, :action => :password_form
  end


  private

  def user_can_edit?(params)
    record_info = JSONModel.parse_reference(params[:uri])

    case record_info[:type]
    when 'accession'
      user_can?('update_accession_record', record_info[:repository])
    when 'resource', 'archival_object'
      user_can?('update_resource_record', record_info[:repository])
    when 'digital_object', 'digital_object_component'
      user_can?('update_digital_object_record', record_info[:repository])
    when /^agent/
      user_can?('update_agent_record', record_info[:repository])
    when /^classification/
      user_can?('update_classification_record', record_info[:repository])
    when 'subject'
      user_can?('update_subject_record', record_info[:repository])
    when 'top_container'
      user_can?('update_container_record', record_info[:repository])
    end
  end

  def check_user_access(params)
    record_info = JSONModel.parse_reference(params[:uri])

    can_edit = user_can_edit?(params)

    can_view = user_can?('view_repository', record_info[:repository])

    if can_edit
      mode = AppConfig[:pui_staff_link_mode] || 'edit'
    elsif can_view
      mode = 'readonly'
    else
      mode = nil
    end

    {
      can_access: can_edit || can_view,
      mode: mode
    }
  end

  def set_pui_cors_headers
    response.headers['Access-Control-Allow-Origin'] = AppConfig[:public_proxy_url]
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  def user_can_view_pui?
    user_can?('view_pui')
  end

  def pui_handoff_response
    pui_session = User.request_pui_session

    if pui_session
      {
        session: pui_session['session'],
        username: pui_session['username'],
        view_pui: true
      }
    else
      { view_pui: false }
    end
  rescue StandardError => e
    Rails.logger.error("check_session: could not reach the backend to request a PUI session (#{e.class}: #{e.message})")
    Rails.logger.error("Stacktrace:\n%s" % [e.backtrace.join("\n")])
    { view_pui: false }
  end

  # Failed login limits per username and per client IP.
  # nil, false, 0 or text in a setting turns that limit off.
  def login_throttle_period
    AppConfig[:frontend_login_throttle_period].to_s.to_i
  end

  def login_username_key(username)
    "staff_login:#{username.to_s.strip.downcase}"
  end

  # Each Fail2Ban key with its failure limit, for the limits that are on.
  def login_failure_limits(username)
    return {} unless login_throttle_period > 0

    {
      login_username_key(username) => AppConfig[:frontend_login_throttle_limit].to_s.to_i,
      "staff_login_ip:#{request.remote_ip}" => AppConfig[:frontend_login_ip_throttle_limit].to_s.to_i
    }.select { |_key, limit| limit > 0 }
  end

  def login_throttled?(username)
    login_failure_limits(username).keys.any? { |key| Rack::Attack::Fail2Ban.banned?(key) }
  end

  def record_login_failure(username)
    login_failure_limits(username).each do |key, limit|
      Rack::Attack::Fail2Ban.filter(key, maxretry: limit, findtime: login_throttle_period, bantime: login_throttle_period) { true }
    end
  end

  # Reset only the username count. If a successful login reset the IP count, an attacker
  # with any valid account could log in to it between guesses and never reach the IP limit.
  def reset_login_failures(username)
    return unless login_failure_limits(username).key?(login_username_key(username))

    Rack::Attack::Fail2Ban.reset(login_username_key(username), findtime: login_throttle_period)
  end
end
