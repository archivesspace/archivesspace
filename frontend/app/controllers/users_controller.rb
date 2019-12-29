class UsersController < ApplicationController

    set_access_control "manage_users" => [:index, :edit, :update, :delete, :activate, :deactivate],
                      "manage_repository" => [:manage_access, :edit_groups, :update_groups, :complete],
                      :public => [:new, :create]

  before_action :account_self_service, :only => [:new, :create]
  before_action :user_needs_to_be_a_user_manager_or_new_user, :only => [:new, :create]
  before_action :user_needs_to_be_a_user, :only => [:show]

  def index
    show_inactive = params[:show_inactive] || false
    @search_data = JSONModel(:user).all(:page => selected_page, :show_inactive => show_inactive)
  end

  def manage_access
    @search_data = JSONModel(:user).all(:page => selected_page)
    @manage_access = true
    render :action => "index"
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
      flash[:error] = I18n.t("user._frontend.messages.access_denied", JSONModelI18nWrapper.new(:user => @user))
      redirect_to(:controller => :users, :action => :index) and return
    end

    render action: "edit"
  end

  def edit_groups
    @user = JSONModel(:user).from_hash(JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/users/#{params[:id]}"))

    if @user.is_system_user or @user.is_admin
      flash[:error] = I18n.t("user._frontend.messages.group_not_required", JSONModelI18nWrapper.new(:user => @user))
      redirect_to(:controller => :users, :action => :manage_access) and return
    end

    @groups = JSONModel(:group).all
    render action: "edit_groups"
  end

  def delete
    user = JSONModel(:user).find(params[:id])
    user.delete

    flash[:success] = I18n.t("user._frontend.messages.deleted", JSONModelI18nWrapper.new(:user => user))
    redirect_to(:controller => :users, :action => :index, :deleted_uri => user.uri)
  end

  def update

    handle_crud(:instance => :user,
                :obj => JSONModel(:user).find(params[:id]),
                :params_check => ->(obj, params){
                  if params['user']['password'] || params['user']['confirm_password']
                    if params['user']['password'] != params['user']['confirm_password']
                      obj.add_error('confirm_password', "entered value didn't match password")
                    end
                  end
                },
                :on_invalid => ->(){
                  flash[:error] = I18n.t("user._frontend.messages.error_update")
                  render :action => "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("user._frontend.messages.updated")
                  redirect_to :action => :index
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
      flash[:success] = I18n.t("user._frontend.messages.updated")
      redirect_to :action => :manage_access
    else
      flash[:error] = I18n.t("user._frontend.messages.error_update")
      @groups = JSONModel(:group).all if user_can?('manage_repository')

      render :action => :edit_groups
    end

  end


  def create

    handle_crud(:instance => :user,
                :params_check => ->(obj, params){
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
                :on_invalid => ->(){
                  flash[:error] = I18n.t("user._frontend.messages.error_create")
                  render :action => "new"
                },
                :on_valid => ->(id){
                  if session[:user]
                    flash[:success] = "#{I18n.t("user._frontend.messages.created")}: #{params['user']['username']}"
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
      flash[:success] = I18n.t("user._frontend.messages.activated")
    else
      flash[:error] = I18n.t("user._frontend.messages.error_activate")
    end
    redirect_to :action => :index
  end

  def deactivate
    if JSONModel::HTTP::get_json("/users/#{params[:id]}/deactivate")
      flash[:success] = I18n.t("user._frontend.messages.deactivated")
    else
      flash[:error] = I18n.t("user._frontend.messages.error_deactivate")
    end
    redirect_to :action => :index
  end

  private


  def selected_page
    [Integer(params[:page] || 1), 1].max
  end

end
