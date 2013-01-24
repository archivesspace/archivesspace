class DigitalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :tree, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :tree]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  FIND_OPTS = ["subjects", "linked_agents", "linked_instances"]

  def index
    @search_data = JSONModel(:digital_object).all(:page => selected_page)
  end

  def show
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)

    if params[:inline]
      return render :partial => "digital_objects/show_inline"
    end

    fetch_tree
  end

  def new
    @digital_object = JSONModel(:digital_object).new({:title => I18n.t("digital_object.title_default")})._always_valid!

    return render :partial => "digital_objects/new" if params[:inline]
  end

  def edit
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)

    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    return render :partial => "digital_objects/edit_inline" if params[:inline]

    fetch_tree
  end


  def create
    handle_crud(:instance => :digital_object,
                :on_invalid => ->(){
                  return render :partial => "new" if inline? 
                  render :action => "new" 
                },
                :on_valid => ->(id){
                  return render :json => @digital_object.to_hash if inline?
                  redirect_to({
                                :controller => :digital_objects,
                                :action => :edit,
                                :id => id
                              },
                              :flash => {:success => I18n.t("digital_object._html.messages.created")}) 
                })
  end


  def update
    handle_crud(:instance => :digital_object,
                :obj => JSONModel(:digital_object).find(params[:id],
                                                  "resolve[]" => FIND_OPTS),
                :on_invalid => ->(){
                  render :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  flash.now[:success] = I18n.t("digital_object._html.messages.updated")
                  render :partial => "edit_inline"
                })
  end


  private

  def fetch_tree
    @tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => @digital_object.id)
  end

end
