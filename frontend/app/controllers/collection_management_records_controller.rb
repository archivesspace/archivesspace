class CollectionManagementRecordsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_archival_record")}

  def index
    @search_data = JSONModel(:collection_management).all(:page => 1)
  end

  def show
    @collection_management = JSONModel(:collection_management).find(params[:id], "resolve[]" => ["linked_records"])
  end

  def new
    @collection_management = JSONModel(:collection_management).new._always_valid!
    @collection_management.linked_records = [{}]
  end

  def edit
    @collection_management = JSONModel(:collection_management).find(params[:id], "resolve[]" => ["linked_records"])
  end

  def create
    handle_crud(:instance => :collection_management,
                :on_invalid => ->(){
                  render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("collection_management._frontend.messages.created")
                  return redirect_to :controller => :collection_management_records, :action => :new if params.has_key?(:plus_one)

                  redirect_to :controller => :collection_management_records, :action => :index, :id => id
                })
  end

  def update
    handle_crud(:instance => :collection_management,
                :obj => JSONModel(:collection_management).find(params[:id]),
                :on_invalid => ->(){ render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("collection_management._frontend.messages.updated")
                  redirect_to :controller => :collection_management_records, :action => :index
                })
  end

end
