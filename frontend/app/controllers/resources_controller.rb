class ResourcesController < ApplicationController

  def index
    @resources = JSONModel(:resource).all
  end

  def show
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => "subjects")

    if params[:inline]
      return render :partial => "resources/show_inline"
    end

    fetch_resource_tree(@resource)
  end

  def new
    @resource = JSONModel(:resource).new({:title => "New Resource"})._always_valid!
  end

  def edit
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => "subjects")

    if params[:inline]
      return render :partial => "resources/edit_inline"
    end

    fetch_resource_tree(@resource)
  end


  def create
    handle_crud(:instance => :resource,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){ redirect_to(:controller => :resources,
                                                 :action => :edit,
                                                 :id => id) })
  end


  def update
    handle_crud(:instance => :resource,
                :obj => JSONModel(:resource).find(params[:id],
                                                  "resolve[]" => "subjects"),
                :on_invalid => ->(){
                  render :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  flash[:success] = "Resource Saved"
                  render :partial => "edit_inline"
                })
  end


  def destroy

  end

  def tree
    fetch_resource_tree(JSONModel(:resource).find(params[:id]))
    render :text => @resource_tree.to_json
  end

  def update_tree
    begin
      tree = JSONModel(:resource_tree).from_json(params[:tree])
      tree.save(:resource_id => params[:id])
      render :text => "Success"
    rescue JSONModel::ValidationException => e
      render :text => "Error"
    end
  end


  private

  def convert_refs_to_ids(tree)
    tree["id"] = JSONModel(:archival_object).id_for(tree["archival_object"])

    tree["children"].each do |child|
      convert_refs_to_ids(child)
    end

    tree
  end

  def fetch_resource_tree(resource)
    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    @resource_tree = {
      "resource_id" => resource.id,
      "title" => resource.title,
      "children" => tree ? [convert_refs_to_ids(tree.to_hash)] : []
    }
  end

end
