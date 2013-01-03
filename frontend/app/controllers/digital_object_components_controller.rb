class DigitalObjectComponentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :parent]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update, :parent]


  FIND_OPTS = {
    "resolve[]" => ["subjects","linked_agents"]
  }


  def new
    @digital_object_component = JSONModel(:digital_object_component).new._always_valid!
    @digital_object_component.title = "New Digital Object Component"
    @digital_object_component.parent = JSONModel(:digital_object_component).uri_for(params[:digital_object_component_id]) if params.has_key?(:digital_object_component_id)
    @digital_object_component.digital_object = JSONModel(:digital_object).uri_for(params[:digital_object_id]) if params.has_key?(:digital_object_id)

    return render :partial => "digital_object_components/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], FIND_OPTS)
    render :partial => "digital_object_components/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :digital_object_component,
                :find_opts => FIND_OPTS,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Digital Object Component Created"
                  render :partial => "digital_object_components/edit_inline"
                })
  end


  def update
    handle_crud(:instance => :digital_object_component,
                :obj => JSONModel(:digital_object_component).find(params[:id], FIND_OPTS),
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  flash[:success] = "Digital Object Component Saved"
                  render :partial => "edit_inline"
                })
  end


  def show
    @digital_object_id = params['digital_object_id']
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], FIND_OPTS)
    render :partial => "digital_object_components/show_inline" if inline?
  end


  def parent
    params[:digital_object_component] ||= {}
    if params[:parent] and not params[:parent].blank?
      # set parent as DOC uri on params
      params[:digital_object_component][:parent] = JSONModel(:digital_object_component).uri_for(params[:parent])
    else
      #remove parent from DOC
      params[:digital_object_component][:parent] = nil
    end

    params[:digital_object_component][:position] = params[:index].to_i if params.has_key? :index

    handle_crud(:instance => :digital_object_component,
                :obj => JSONModel(:digital_object_component).find(params[:id]),
                :replace => false,
                :on_invalid => ->(){ raise "Error setting parent of digital object component" },
                :on_valid => ->(id){ return render :text => "success"})
  end

end
