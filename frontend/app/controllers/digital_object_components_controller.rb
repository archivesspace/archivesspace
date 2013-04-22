class DigitalObjectComponentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :parent]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :parent]) {|c| user_must_have("update_archival_record")}


  FIND_OPTS = {
    "resolve[]" => ["subjects", "linked_agents", "digital_object", "parent"]
  }


  def new
    @digital_object_component = JSONModel(:digital_object_component).new._always_valid!
    @digital_object_component.title = I18n.t("digital_object_component.title_default")
    @digital_object_component.parent = {'ref' => JSONModel(:digital_object_component).uri_for(params[:digital_object_component_id])} if params.has_key?(:digital_object_component_id)
    @digital_object_component.digital_object = {'ref' => JSONModel(:digital_object).uri_for(params[:digital_object_id])} if params.has_key?(:digital_object_id)

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
                  # Refetch the record to ensure all sub records are resolved
                  # (this object isn't marked as stale upon create like Archival Objects,
                  # so need to do it manually)
                  @digital_object_component = JSONModel(:digital_object_component).find(id, FIND_OPTS)

                  success_message = @digital_object_component.parent ?
                    I18n.t("digital_object_component._html.messages.created_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved'], :parent => @digital_object_component['parent']['_resolved'])) :
                    I18n.t("digital_object_component._html.messages.created", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved']))

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message

                    return render :partial => "digital_object_components/edit_inline"
                  end

                  flash.now[:success] = success_message
                  render :partial => "digital_object_components/edit_inline"
                })
  end


  def update
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], FIND_OPTS)
    digital_object = @digital_object_component['digital_object']['_resolved']
    parent = @digital_object_component['parent'] ? @digital_object_component['parent']['_resolved'] : false

    handle_crud(:instance => :digital_object_component,
                :obj => @digital_object_component,
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("digital_object_component._html.messages.updated_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object, :parent => parent)) :
                    I18n.t("digital_object_component._html.messages.updated", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object))
                  flash.now[:success] = success_message

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
      params[:digital_object_component][:parent] = {'ref' => JSONModel(:digital_object_component).uri_for(params[:parent])}
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
