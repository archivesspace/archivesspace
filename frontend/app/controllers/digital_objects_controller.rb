class DigitalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :tree, :new, :edit, :create, :update, :update_tree]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :tree]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update, :update_tree]

  def index
    @digital_objects = JSONModel(:digital_object).all
  end

  def show
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => ["subjects","ref"])

    if params[:inline]
      return render :partial => "digital_objects/show_inline"
    end

    fetch_digital_object_tree(@digital_object)
  end

  def new
    @digital_object = JSONModel(:digital_object).new({:title => "New Digital Object"})._always_valid!
  end

  def edit
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => ["subjects","ref"])

    if params[:inline]
      return render :partial => "digital_objects/edit_inline"
    end

    fetch_digital_object_tree(@digital_object)
  end


  def create
    handle_crud(:instance => :digital_object,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){ redirect_to(:controller => :digital_objects,
                                                 :action => :edit,
                                                 :id => id) })
  end


  def update
    handle_crud(:instance => :digital_object,
                :obj => JSONModel(:digital_object).find(params[:id],
                                                  "resolve[]" => ["subjects","ref"]),
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
    fetch_digital_object_tree(JSONModel(:digital_object).find(params[:id]))
    render :text => @digital_object_tree.to_json
  end

  def update_tree
    begin
      tree = JSONModel(:digital_object_tree).from_json(params[:tree])
      tree.save(:digital_object_id => params[:id])
      render :text => "Success"
    rescue JSONModel::ValidationException => e
      render :text => "Error"
    end
  end


  private

  def convert_refs_to_ids(tree)
    tree["id"] = JSONModel(:digital_object_component).id_for(tree["digital_object_component"])

    tree["children"].each do |child|
      convert_refs_to_ids(child)
    end

    tree
  end

  def fetch_digital_object_tree(digital_object)
    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)

    @digital_object_tree = {
      "digital_object_id" => digital_object.id,
      "title" => digital_object.title,
      "children" => tree ? [convert_refs_to_ids(tree.to_hash)] : []
    }
  end

end
