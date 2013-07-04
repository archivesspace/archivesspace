class GroupsController < ApplicationController

  set_access_control  "manage_repository" => [:new, :index, :edit, :create, :update, :show, :delete]


  def new
    @group = JSONModel(:group).new._always_valid!
  end


  def index
    @groups = JSONModel(:group).all
  end


  def show
    redirect_to :action => :index
  end


  def edit
    @group = JSONModel(:group).find(params[:id])
  end


  def create
    handle_crud(:instance => :group,
                :on_invalid => ->(){ render :action => "new" },
                :on_valid => ->(id){ redirect_to(:controller => :groups, :action => :index) })
  end


  def update
    params[:group][:grants_permissions] ||= []
    params[:group][:member_usernames] ||= []

    handle_crud(:instance => :group,
                :model => Accession,
                :obj => JSONModel(:group).find(params[:id]),
                :replace => false,
                :on_invalid => ->(){
                  return render :action => "edit"
                },
                :on_valid => ->(id){
                  redirect_to(:controller => :groups, :action => :index)
                })
  end


  def delete
    group = JSONModel(:group).find(params[:id])
    group.delete

    redirect_to(:controller => :groups, :action => :index, :deleted_uri => group.uri)
  end

end
