class CollectionManagementRecordsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_archival_record" => [:new, :edit, :create, :update]


  def index
    @search_data = JSONModel(:collection_management).all(:page => 1)
  end

  def current_record
    @collection_management
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
                :on_invalid => ->() {
                  render :action => :new
                },
                :on_valid => ->(id) {
                  flash[:success] = t("collection_management._frontend.messages.created")
                  return redirect_to :controller => :collection_management_records, :action => :new if params.has_key?(:plus_one)

                  redirect_to :controller => :collection_management_records, :action => :index, :id => id
                })
  end

  def update
    handle_crud(:instance => :collection_management,
                :obj => JSONModel(:collection_management).find(params[:id]),
                :on_invalid => ->() { render :action => :edit },
                :on_valid => ->(id) {
                  flash[:success] = t("collection_management._frontend.messages.updated")
                  redirect_to :controller => :collection_management_records, :action => :index
                })
  end

end
