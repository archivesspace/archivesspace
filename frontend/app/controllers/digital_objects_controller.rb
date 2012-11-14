class DigitalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :tree, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :tree]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @search_data = JSONModel(:digital_object).all(:page => selected_page)
  end

  def show
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => ["subjects","ref"])

    if params[:inline]
      return render :partial => "digital_objects/show_inline"
    end

    fetch_tree
  end

  def new
    @digital_object = JSONModel(:digital_object).new({:title => "New Digital Object"})._always_valid!
  end

  def edit
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => ["subjects","ref"])

    if params[:inline]
      return render :partial => "digital_objects/edit_inline"
    end

    fetch_tree
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


  private

  def fetch_tree
    @tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => @digital_object.id)
  end

end
