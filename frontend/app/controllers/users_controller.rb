class UsersController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :complete, :edit, :index, :create, :update, :show, :manage_access, :edit_groups, :update_groups]
  before_filter(:only => [:index, :edit, :update]) {|c| user_must_have("manage_users")}
  before_filter(:only => [:manage_access, :edit_groups, :update_groups, :complete]) {|c| user_must_have("manage_repository")}
  before_filter :user_needs_to_be_a_user_manager_or_new_user, :only => [:new, :create]
  before_filter :user_needs_to_be_a_user, :only => [:show]

  def index
    @search_data = JSONModel(:user).all(:page => selected_page)
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
    @user = JSONModel(:user).new._always_valid!
    render action: "new"
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
    render action: "edit"
  end

  def edit_groups
    @user = JSONModel(:user).from_hash(JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/users/#{params[:id]}"))
    @groups = JSONModel(:group).all if user_can?('manage_users')
    render action: "edit_groups"
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
                  flash[:error] = I18n.t("user._html.messages.error_update")
                  render :action => "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("user._html.messages.updated")
                  redirect_to :action => :index
                })
  end

  def update_groups

    handle_crud(:instance => :user,
                :obj => JSONModel(:user).from_hash(JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/users/#{params[:id]}")),
                :save_opts => {
                  "groups[]" => Array(params[:groups]),
                  :repo_id => session[:repo_id]
                },
                :replace => false,
                :on_invalid => ->(){
                  flash[:error] = I18n.t("user._html.messages.error_update")
                  @groups = JSONModel(:group).all if user_can?('manage_users')

                  render :action => :edit_groups
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("user._html.messages.updated")
                  redirect_to :action => :manage_access
                })
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
                },
                :on_invalid => ->(){
                  flash[:error] = I18n.t("user._html.messages.error_create")
                  render :action => "new"
                },
                :on_valid => ->(id){
                  
                  if session[:user]
                    flash[:success] = "#{I18n.t("user._html.messages.created")}: #{params['user']['username']}"
                    redirect_to :controller => :users, :action => :index
                  else
                    backend_session = User.login(params['user']['username'],
                                               params['user']['password'])

                    User.establish_session(session, backend_session, params['user']['username'])

                    redirect_to :controller => :welcome, :action => :index

                  end
                  
                })
  end
end
