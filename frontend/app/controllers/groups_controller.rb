class GroupsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :index, :edit, :create, :update]
  before_filter :user_needs_to_be_a_manager, :only => [:new, :index, :edit, :create, :update]

  def new
    @group = JSONModel(:group).new._always_valid!
  end


  def index
    @groups = JSONModel(:group).all
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

end
