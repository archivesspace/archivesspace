class GroupsController < ApplicationController

  set_access_control "manage_repository" => [:new, :index, :edit, :create, :update, :show, :delete]

  after_action :update_global_group, only: :update, if: -> { params[:group][:group_code] == 'repository-pui-viewers' }

  def new
    @group = JSONModel(:group).new._always_valid!
  end


  def index
    @groups = JSONModel(:group).all
    # Hide if functionality not on.  Or do we want to show it by have it inactive/uneditable a la enumeration values?
    if AppConfig[:pui_require_authentication] == false
      @groups = @groups.reject { |grp| grp.group_code == 'repository-pui-viewers' }
    end
  end


  def current_record
    @group
  end


  def show
    redirect_to :action => :index
  end


  def edit
    @group = JSONModel(:group).find(params[:id])
  end


  def create
    handle_crud(:instance => :group,
                :on_invalid => ->() { render :action => "new" },
                :on_valid => ->(id) { redirect_to(:controller => :groups, :action => :index) })
  end


  def update
    params[:group][:grants_permissions] ||= []
    params[:group][:member_usernames] ||= []

    handle_crud(:instance => :group,
                :model => JSONModel(:group),
                :obj => JSONModel(:group).find(params[:id]),
                :replace => false,
                :on_invalid => ->() {
                  return render :action => "edit"
                },
                :on_valid => ->(id) {
                  redirect_to(:controller => :groups, :action => :index)
                })
  end


  def delete
    group = JSONModel(:group).find(params[:id])
    group.delete

    redirect_to(:controller => :groups, :action => :index, :deleted_uri => group.uri)
  end

  private

  def update_global_group
   # Need to figure out how to get this global group uri
    uri = "/repositories/1/groups/5"
    global_group = JSONModel::HTTP::get_json(uri)
    global_group['member_usernames'] = Array(params[:group][:member_usernames])

    post_data = global_group
    post_uri = "#{JSONModel::HTTP.backend_url}#{uri}"
    response = JSONModel::HTTP::post_json(URI(post_uri), post_data.to_json)
    result = ASUtils.json_parse(response.body)
  end

end
