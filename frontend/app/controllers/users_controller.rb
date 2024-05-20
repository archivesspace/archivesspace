require 'zxcvbn'

class UsersController < ApplicationController

  set_access_control "manage_users" => [:index, :edit, :update, :delete, :activate, :deactivate],
                    "manage_repository" => [:manage_access, :edit_groups, :update_groups],
                    "edit_user_self" => [:edit_self, :update_self],
                    :public => [:new, :create, :complete, :password_form, :recover_password, :update_password]

  before_action :account_self_service, :only => [:new, :create]
  before_action :user_needs_to_be_a_user_manager_or_new_user, :only => [:new, :create]
  before_action :user_needs_to_be_a_user, :only => [:show, :complete, :edit_self, :update_self]


  def index
    @search_data = JSONModel(:user).all(
      page: selected_page,
      page_size: 50,
      sort_field: params.fetch(:sort, :username),
      sort_direction: params.fetch(:direction, :asc)
    )
  end

  def manage_access
    @search_data = JSONModel(:user).all(
      page: selected_page,
      page_size: 50,
      sort_field: params.fetch(:sort, :username),
      sort_direction: params.fetch(:direction, :asc)
    )
    @manage_access = true
    render :action => "index"
  end

  def current_record
    @user
  end

  def show
    @user = JSONModel(:user).find(params[:id])
    render action: "show"
  end

  def new
    if AppConfig[:allow_user_registration] or (session['user'] and user_can? 'manage_users')
      @user = JSONModel(:user).new._always_valid!
      render action: "new"
    else
      redirect_to(:controller => :welcome, :action => :index)
    end
  end

  def complete
    query = params[:query].strip
    if !query.empty?
      begin
        return render :json => JSONModel::HTTP::get_json("/users/complete", :query => params[:query])
      rescue
      end
    end

    render :json => []
  end

  def edit
    @user = JSONModel(:user).find(params[:id])

    if @user.is_system_user and not user_is_global_admin?
      flash[:error] = t("user._frontend.messages.access_denied")
      redirect_to(:controller => :users, :action => :index) and return
    end

    render action: "edit"
  end

  def edit_self
    @user = JSONModel(:user).find('current-user')
    @self_edit = true

    render action: "edit_self"
  end

  def edit_groups
    @user = JSONModel(:user).from_hash(JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/users/#{params[:id]}"))

    if @user.is_system_user or @user.is_admin
      flash[:error] = t("user._frontend.messages.group_not_required")
      redirect_to(:controller => :users, :action => :index) and return
    end

    @groups = JSONModel(:group).all
    render action: "edit_groups"
  end

  def delete
    user = JSONModel(:user).find(params[:id])
    user.delete

    flash[:success] = t("user._frontend.messages.deleted")
    redirect_to(:controller => :users, :action => :index, :deleted_uri => user.uri)
  end

  def update
    handle_crud(:instance => :user,
                :obj => JSONModel(:user).find(params[:id]),
                :params_check => ->(obj, params) {
                  if params['user']['password'] || params['user']['confirm_password']
                    if params['user']['password'] != params['user']['confirm_password']
                      obj.add_error('confirm_password', "entered value didn't match password")
                    end
                  end
                },
                :on_invalid => ->() {
                  flash[:error] = t("user._frontend.messages.error_update")
                  render :action => "edit"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("user._frontend.messages.updated")
                  redirect_to :action => :index
                })
  end

  def update_self
    handle_crud(:instance => :user,
                :obj => obj = JSONModel(:user).find('current-user'),
                :params_check => ->(obj, params) {
                  if params['user']['password'] || params['user']['confirm_password']
                    if params['user']['password'] != params['user']['confirm_password']
                      obj.add_error('confirm_password', "entered value didn't match password")
                    end
                  end
                },
                :on_invalid => ->() {
                  flash[:error] = t("user._frontend.messages.error_update")
                  render :action => "edit_self"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("user._frontend.messages.updated")
                  redirect_to :action => "edit_self"
                })
  end

  def update_groups
    groups = Array(params[:groups])

    uri = "/users/#{params[:id]}/groups"
    response = JSONModel::HTTP.post_form(URI(uri),
                                         'groups[]' => groups,
                                         :remove_groups => groups.empty?,
                                         :repo_id => session[:repo_id]
                                         )

    if response.code === '200'
      flash[:success] = t("user._frontend.messages.updated")
      redirect_to :action => :manage_access
    else
      flash[:error] = t("user._frontend.messages.error_update")
      @groups = JSONModel(:group).all if user_can?('manage_repository')

      render :action => :edit_groups
    end
  end


  def create
    handle_crud(:instance => :user,
                :params_check => ->(obj, params) {
                  ['password', 'confirm_password'].each do |field|
                    if params['user'][field].blank?
                      obj.add_error(field, "Can't be empty")
                    end
                  end
                  if params['user']['password'] != params['user']['confirm_password']
                    obj.add_error('confirm_password', "entered value didn't match password")
                  end
                  s = params['user']['username'].downcase.strip
                  if s.blank?
                    obj.add_error('username', "Can't be empty")
                  elsif s !~ /\A[a-zA-Z0-9\-_. @]+\z/ || s =~ /  +/
                    obj.add_error('username', 'invalid characters')
                  end
                },
                :on_invalid => ->() {
                  flash[:error] = t("user._frontend.messages.error_create")
                  render :action => "new"
                },
                :on_valid => ->(id) {
                  if session[:user]
                    flash[:success] = "#{t("user._frontend.messages.created")}: #{params['user']['username']}"
                    redirect_to :controller => :users, :action => :index
                  else
                    backend_session = User.login(params['user']['username'],
                                               params['user']['password'])

                    User.establish_session(self, backend_session, params['user']['username'])

                    redirect_to :controller => :welcome, :action => :index

                  end
                })
  end

  def activate
    if JSONModel::HTTP::get_json("/users/#{params[:id]}/activate")
      flash[:success] = t("user._frontend.messages.activated")
    else
      flash[:error] = t("user._frontend.messages.error_activate")
    end
    redirect_to :action => :index
  end

  def deactivate
    if JSONModel::HTTP::get_json("/users/#{params[:id]}/deactivate")
      flash[:success] = t("user._frontend.messages.deactivated")
    else
      flash[:error] = t("user._frontend.messages.error_deactivate")
    end
    redirect_to :action => :index
  end

  def password_form; end

  def recover_password
    if !AppConfig[:allow_password_reset]
      flash[:error] = I18n.t("user._frontend.messages.password_reset_not_allowed", email: params.fetch(:email))
    else
      result = User.recover_password(params.fetch(:email, nil))
      if result[:status] == :success || result[:status] == :not_found
        flash[:success] = I18n.t("user._frontend.messages.password_reset_email_sent", email: params.fetch(:email))
      else
        flash[:error] = result[:error]
      end
    end

    redirect_to action: :password_form
  end

  def update_password
    user_id = JSONModel(:user).id_for(session["user_uri"])
    unless params[:password] == params[:confirm_password]
      flash[:error] = I18n.t('login.password_mismatch_error')
      return redirect_to action: :password_form
    end

    # it just seems wrong to allow single character or three letter word
    # passwords. It is still allowed; but if you forget your single
    # character or three letter word password your punishment is this requirement.
    # A future refactor could make these thresholds settable in AppConfig...
    score = Zxcvbn.test(params[:password])
    if score.entropy < 12 || score.crack_time < 2
      flash[:error] = I18n.t('login.password_too_simple')
      return redirect_to action: :password_form
    end

    response = JSONModel::HTTP.post_form("/users/#{user_id}/password", {
                                           password: params[:password]
                                         })
    if response.code == "200"
      reset_session
      flash[:success] = I18n.t('login.password_update_success')
      return redirect_to controller: :welcome, action: :index, login: true
    else
      flash[:error] = I18n.t('login.password_update_error')
      return redirect_to action: :password_form, login: true
    end
  end

  private


  def selected_page
    [Integer(params[:page] || 1), 1].max
  end

end
