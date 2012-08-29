class ArchivalObjectsController < ApplicationController

  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.title = "New Archival Object"
    @archival_object.parent = JSONModel(:archival_object).uri_for(params[:parent]) if params.has_key?(:parent)
    @archival_object.resource = JSONModel(:resource).uri_for(params[:resource]) if params.has_key?(:resource)

    return render :partial => "archival_objects/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @archival_object = JSONModel(:archival_object).find(params[:id], "resolve[]" => "subjects")
    render :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){ render :partial => "archival_objects/edit_inline" })
  end


  def update
    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id],
                                                         "resolve[]" => "subjects"),
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Archival Object Saved"
                  render :partial => "edit_inline"
                })
  end

end
