class ArchivalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :parent]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update, :parent]

  FIND_OPTS = {
    "resolve[]" => ["subjects", "location", "linked_agents"]
  }

  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.title = "New Archival Object"
    @archival_object.parent = JSONModel(:archival_object).uri_for(params[:archival_object_id]) if params.has_key?(:archival_object_id)
    @archival_object.resource = JSONModel(:resource).uri_for(params[:resource_id]) if params.has_key?(:resource_id)

    return render :partial => "archival_objects/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @archival_object = JSONModel(:archival_object).find(params[:id], FIND_OPTS)
    render :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :find_opts => FIND_OPTS,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Archival Object Created"
                  render :partial => "archival_objects/edit_inline"
                })
  end


  def update
    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id], FIND_OPTS),
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Archival Object Saved"
                  render :partial => "edit_inline"
                })
  end


  def show
    @resource_id = params['resource_id']
    @archival_object = JSONModel(:archival_object).find(params[:id], FIND_OPTS)
    render :partial => "archival_objects/show_inline" if inline?
  end


  def parent
    params[:archival_object] ||= {}
    if params[:parent] and not params[:parent].blank?
      # set parent as AO uri on params
      params[:archival_object][:parent] = JSONModel(:archival_object).uri_for(params[:parent])
    else
      #remove parent from AO
      params[:archival_object][:parent] = nil
    end

    params[:archival_object][:position] = params[:index].to_i if params.has_key? :index

    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id]),
                :replace => false,
                :on_invalid => ->(){
                  raise "Error setting parent of archival object"
                },
                :on_valid => ->(id){ return render :text => "success"})
  end

end
