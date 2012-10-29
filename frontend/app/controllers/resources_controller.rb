class ResourcesController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :children, :new, :edit, :create, :update, :update_tree]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :children]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update, :update_tree]

  def index
    @resources = JSONModel(:resource).all
  end

  def show
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => ["subjects", "location", "ref"])

    if params[:inline]
      return render :partial => "resources/show_inline"
    end

    fetch_resource_tree(@resource)
  end

  def new
    @resource = JSONModel(:resource).new({:title => "New Resource"})._always_valid!
    @resource.extents = [JSONModel(:extent).new._always_valid!]
  end

  def edit
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => ["subjects", "location", "ref"])
    fetch_resource_tree(@resource)
    return render :partial => "resources/edit_inline" if params[:inline]
  end


  def create
    handle_crud(:instance => :resource,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                  flash[:success] = "Resource Created"
                  redirect_to(:controller => :resources,
                                                 :action => :edit,
                                                 :id => id)
                 })
  end


  def update
    handle_crud(:instance => :resource,
                :obj => JSONModel(:resource).find(params[:id],
                                                  "resolve[]" => ["subjects", "location", "ref"]),
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

  def children
    if params[:archival_object_id]
      children = JSONModel::HTTP.get_json("#{JSONModel(:archival_object).uri_for(params[:archival_object_id])}/children")
    else
      children = JSONModel::HTTP.get_json("#{JSONModel(:resource).uri_for(params[:id])}/tree")
    end
    render :json => children
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

  def convert_refs_to_ids(node)
    node["id"] = JSONModel(:archival_object).id_for(node["uri"])

    node.children.collect! {|n| convert_refs_to_ids(n)}

    node
  end

  def fetch_resource_tree(resource)
    tree = JSONModel::HTTP.get_json("#{JSONModel(:resource).uri_for(params[:id])}/tree")

    @resource_tree = {
      "resource_id" => resource.id,
      "title" => resource.title,
      "children" => [tree]
    }
  end

end
