class DigitalObjectComponentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_digital_object_record" => [:new, :edit, :create, :update, :accept_children, :rde, :add_children, :validate_rows],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete]


  def new
    @digital_object_component = JSONModel(:digital_object_component).new._always_valid!
    @digital_object_component.title = I18n.t("digital_object_component.title_default", :default => "")
    @digital_object_component.parent = {'ref' => JSONModel(:digital_object_component).uri_for(params[:digital_object_component_id])} if params.has_key?(:digital_object_component_id)
    @digital_object_component.digital_object = {'ref' => JSONModel(:digital_object).uri_for(params[:digital_object_id])} if params.has_key?(:digital_object_id)

    return render_aspace_partial :partial => "digital_object_components/new_inline" if inline?

    # render the full DOC form

  end

  def edit
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], find_opts)

    if @digital_object_component.suppressed
      return redirect_to(:action => :show, :id => params[:id], :inline => params[:inline])
    end

    render_aspace_partial :partial => "digital_object_components/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :digital_object_component,
                :find_opts => find_opts,
                :on_invalid => ->(){ render_aspace_partial :partial => "new_inline" },
                :on_valid => ->(id){
                  # Refetch the record to ensure all sub records are resolved
                  # (this object isn't marked as stale upon create like Archival Objects,
                  # so need to do it manually)
                  @digital_object_component = JSONModel(:digital_object_component).find(id, find_opts)

                  success_message = @digital_object_component.parent ?
                    I18n.t("digital_object_component._frontend.messages.created_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved'], :parent => @digital_object_component['parent']['_resolved'])) :
                    I18n.t("digital_object_component._frontend.messages.created", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => @digital_object_component['digital_object']['_resolved']))

                  @refresh_tree_node = true

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  render_aspace_partial :partial => "digital_object_components/edit_inline"
                })
  end


  def update
    params['digital_object_component']['position'] = params['digital_object_component']['position'].to_i if params['digital_object_component']['position']

    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], find_opts)
    digital_object = @digital_object_component['digital_object']['_resolved']
    parent = @digital_object_component['parent'] ? @digital_object_component['parent']['_resolved'] : false

    handle_crud(:instance => :digital_object_component,
                :obj => @digital_object_component,
                :on_invalid => ->(){ return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("digital_object_component._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object, :parent => parent)) :
                    I18n.t("digital_object_component._frontend.messages.updated", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component, :digital_object => digital_object))
                  flash.now[:success] = success_message

                  @refresh_tree_node = true

                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def show
    @digital_object_id = params['digital_object_id']
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], find_opts)

    flash.now[:info] = I18n.t("digital_object_component._frontend.messages.suppressed_info", JSONModelI18nWrapper.new(:digital_object_component => @digital_object_component)) if @digital_object_component.suppressed

    render_aspace_partial :partial => "digital_object_components/show_inline" if inline?
  end


  def delete
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.delete

    flash[:success] = I18n.t("digital_object_component._frontend.messages.deleted", JSONModelI18nWrapper.new(:digital_object_component => digital_object_component))

    resolver = Resolver.new(digital_object_component['digital_object']['ref'])
    redirect_to resolver.view_uri
  end


  def accept_children
    handle_accept_children(JSONModel(:digital_object_component))
  end


  def rde
    flash.clear

    @parent = JSONModel(:digital_object_component).find(params[:id])
    @children = DigitalObjectComponentChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def validate_rows
    row_data = cleanup_params_for_schema(params[:digital_record_children], JSONModel(:digital_record_children).schema)

    # build the DOC record but don't bother validating it yet...
    do_children = DigitalObjectComponentChildren.from_hash(row_data, false, true)

    # validate each row individually (to avoid weird indexes in the error paths)
    render :json => do_children.children.collect{|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}
  end

  def add_children
    @parent = JSONModel(:digital_object_component).find(params[:id])

    if params[:digital_record_children].blank? or params[:digital_record_children]["children"].blank?

      @children = DigitalObjectComponentChildren.new
      flash.now[:error] = I18n.t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:digital_record_children], JSONModel(:digital_record_children).schema)

      begin
        @children = DigitalObjectComponentChildren.from_hash(children_data, false)

        if params["validate_only"] == "true"
          @exceptions = @children.children.collect{|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}

          error_count = @exceptions.select{|e| !e.empty?}.length
          if error_count > 0
            flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => error_count)
          else
            flash.now[:success] = I18n.t("rde.messages.rows_no_errors")
          end

          return render_aspace_partial :partial => "shared/rde"
        else
          @children.save(:digital_object_component_id => @parent.id)
        end

        return render :text => I18n.t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children.children.collect{|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}

        flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => @exceptions.select{|e| !e.empty?}.length)
      end

    end

    render_aspace_partial :partial => "shared/rde"
  end


  def suppress
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.set_suppressed(true)

    flash[:success] = I18n.t("digital_object_component._frontend.messages.suppressed", JSONModelI18nWrapper.new(:digital_object_component => digital_object_component))
    redirect_to(:controller => :digital_objects, :action => :show, :id => JSONModel(:digital_object).id_for(digital_object_component['digital_object']['ref']), :anchor => "tree::digital_object_component_#{params[:id]}")
  end


  def unsuppress
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.set_suppressed(false)

    flash[:success] = I18n.t("digital_object_component._frontend.messages.unsuppressed", JSONModelI18nWrapper.new(:digital_object_component => digital_object_component))
    redirect_to(:controller => :digital_objects, :action => :show, :id => JSONModel(:digital_object).id_for(digital_object_component['digital_object']['ref']), :anchor => "tree::digital_object_component_#{params[:id]}")
  end

end
