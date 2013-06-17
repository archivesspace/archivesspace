class DigitalObjectComponentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :parent, :delete, :accept_children]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :parent, :accept_children]) {|c| user_must_have("update_archival_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  FIND_OPTS = {
    "resolve[]" => ["subjects", "linked_agents", "digital_object", "parent"]
  }


  def new
    @digital_object_component = JSONModel(:digital_object_component).new._always_valid!
    @digital_object_component.title = I18n.t("digital_object_component.title_default", :default => "")
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
                    I18n.t("digital_object_component._frontend.messages.created_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved'], :parent => @digital_object_component['parent']['_resolved'])) :
                    I18n.t("digital_object_component._frontend.messages.created", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved']))

                  @refresh_tree_node = true

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  render :partial => "digital_object_components/edit_inline"
                })
  end


  def update
    params['digital_object_component']['position'] = params['digital_object_component']['position'].to_i if params['digital_object_component']['position']

    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], FIND_OPTS)
    digital_object = @digital_object_component['digital_object']['_resolved']
    parent = @digital_object_component['parent'] ? @digital_object_component['parent']['_resolved'] : false

    handle_crud(:instance => :digital_object_component,
                :obj => @digital_object_component,
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("digital_object_component._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object, :parent => parent)) :
                    I18n.t("digital_object_component._frontend.messages.updated", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object))
                  flash.now[:success] = success_message

                  @refresh_tree_node = true

                  render :partial => "edit_inline"
                })
  end


  def show
    @digital_object_id = params['digital_object_id']
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], FIND_OPTS)
    render :partial => "digital_object_components/show_inline" if inline?
  end


  def parent
    parent_id = (params[:parent] and !params[:parent].blank?) ? params[:parent] : nil
    response = JSONModel::HTTP.post_form(JSONModel(:digital_object_component).uri_for(params[:id]) + "/parent",
                              :parent => parent_id,
                              :position => params[:index])

    if response.code == '200'
      render :json => {
        :parent => parent_id ? JSONModel(:archival_object).uri_for(parent_id) : nil,
        :position => params[:index]
      }
    else
      raise "Error setting parent of digital object component: #{response.body}"
    end
  end


  def delete
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.delete

    flash[:success] = I18n.t("digital_object_component._frontend.messages.deleted", JSONModelI18nWrapper.new(:digital_object_component => digital_object_component))

    resolver = Resolver.new(digital_object_component['digital_object']['ref'])
    redirect_to resolver.view_uri
  end


  def accept_children
    response = JSONModel::HTTP.post_form(JSONModel(:digital_object_component).uri_for(params[:id]) + "/accept_children",
                                         "children[]" => params[:children],
                                         "position" => params[:index].to_i)

    if response.code == '200'
      render :json => {
        :parent => params[:id],
        :position => params[:index].to_i
      }
    else
      raise "Error setting parent of archival objects: #{response.body}"
    end
  end

end
