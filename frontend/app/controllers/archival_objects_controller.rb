class ArchivalObjectsController < ApplicationController

  def index
    @archival_objects = JSONModel(:archival_object).all
  end

  def show
    @archival_object = JSONModel(:archival_object).find(params[:id], "resolve[]" => "subjects")
    @resource_id = params[:resource_id] if params.has_key?(:resource_id)

    render :partial => "archival_objects/show_inline"
  end

  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.title = "New Archival Object"
    @archival_object.parent = JSONModel(:archival_object).uri_for(params[:parent]) if params.has_key?(:parent)
    @archival_object.resource = JSONModel(:resource).uri_for(params[:resource]) if params.has_key?(:resource)
    @archival_object.extents = [JSONModel(:extent).new._always_valid!]

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


  private

  def find_node(children, id)
    children.each do |child|
      return child if child['id'] === id
      result = find_node(child['children'], id)
      return result if result.kind_of? Hash
    end
  end

  def find_parent_node(tree, id)
    tree['children'].each do |child|
      return tree['id'] if child['id'].to_s === id.to_s

      result = find_parent_node(child, id)
      return result if not result.blank?
    end
    nil
  end

end
