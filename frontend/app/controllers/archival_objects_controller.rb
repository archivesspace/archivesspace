class ArchivalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.title = "New Archival Object"
    @archival_object.parent = JSONModel(:archival_object).uri_for(params[:parent]) if params.has_key?(:parent)
    @archival_object.resource = JSONModel(:resource).uri_for(params[:resource]) if params.has_key?(:resource)

    return render :partial => "archival_objects/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @archival_object = JSONModel(:archival_object).find(params[:id], "resolve[]" => ["subjects", "location"])
    render :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Archival Object Created"
                  render :partial => "archival_objects/edit_inline"
                })
  end


  def update
    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id],
                                                         "resolve[]" => ["subjects", "location"]),
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Archival Object Saved"
                  render :partial => "edit_inline"
                })
  end


  def show
    @resource_id = params['resource_id']
    @archival_object = JSONModel(:archival_object).find(params[:id], "resolve[]" => ["subjects", "location"])
    render :partial => "archival_objects/show_inline" if inline?
  end
end
