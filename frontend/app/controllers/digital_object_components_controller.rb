class DigitalObjectComponentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_digital_object_record" => [:new, :edit, :create, :update, :accept_children, :rde, :add_children, :validate_rows],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]


  def new
    @digital_object_component = JSONModel(:digital_object_component).new._always_valid!
    @digital_object_component.title = t("digital_object_component.title_default", :default => "")
    @digital_object_component.parent = {'ref' => JSONModel(:digital_object_component).uri_for(params[:digital_object_component_id])} if params.has_key?(:digital_object_component_id)
    @digital_object_component.digital_object = {'ref' => JSONModel(:digital_object).uri_for(params[:digital_object_id])} if params.has_key?(:digital_object_id)
    @digital_object_component.position = params[:position]

    if user_prefs['default_values']
      defaults = DefaultValues.get 'digital_object_component'

      @digital_object_component.update(defaults.values) if defaults
      @form_title = t("digital_object_component.title_default")
    end


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
                :on_invalid => ->() { return render_aspace_partial :partial => "new_inline" },
                :on_valid => ->(id) {
                  # Refetch the record to ensure all sub records are resolved
                  # (this object isn't marked as stale upon create like Archival Objects,
                  # so need to do it manually)
                  @digital_object_component = JSONModel(:digital_object_component).find(id, find_opts)
                  digital_object = @digital_object_component['digital_object']['_resolved']
                  parent = @digital_object_component['parent']? @digital_object_component['parent']['_resolved'] : false

                  flash[:success] = @digital_object_component.parent ?
                    t("digital_object_component._frontend.messages.created_with_parent", digital_object_component_display_string: @digital_object_component.title, digital_object_title: digital_object['title'], parent_display_string: parent['title']) :
                    t("digital_object_component._frontend.messages.created", digital_object_component_display_string: @digital_object_component.title, digital_object_title: digital_object['title'])

                  if @digital_object_component["is_slug_auto"] == false &&
                     @digital_object_component["slug"] == nil &&
                     params["digital_object_component"] &&
                     params["digital_object_component"]["is_slug_auto"] == "1"

                    flash[:warning] = t("slug.autogen_disabled")
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
                :on_invalid => ->() { return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id) {

                  flash.now[:success] = parent ?
                    t("digital_object_component._frontend.messages.updated_with_parent", digital_object_component_display_string: @digital_object_component.title) :
                    t("digital_object_component._frontend.messages.updated", digital_object_component_display_string: @digital_object_component.title)
                  if @digital_object_component["is_slug_auto"] == false &&
                     @digital_object_component["slug"] == nil &&
                     params["digital_object_component"] &&
                     params["digital_object_component"]["is_slug_auto"] == "1"

                    flash.now[:warning] = t("slug.autogen_disabled")
                  end

                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def current_record
    @digital_object_component
  end


  def show
    @digital_object_id = params['digital_object_id']
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], find_opts)

    flash.now[:info] = t("digital_object_component._frontend.messages.suppressed_info") if @digital_object_component.suppressed

    render_aspace_partial :partial => "digital_object_components/show_inline" if inline?
  end


  def delete
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.delete

    flash[:success] = t("digital_object_component._frontend.messages.deleted", digital_object_component_display_string: digital_object_component.title)

    resolver = Resolver.new(digital_object_component['digital_object']['ref'])
    redirect_to resolver.view_uri
  end


  def accept_children
    handle_accept_children(JSONModel(:digital_object_component))
  end

  def defaults
    defaults = DefaultValues.get 'digital_object_component'

    values = defaults ? defaults.form_values : {}

    @digital_object_component = JSONModel(:digital_object_component).new(values)._always_valid!

    @digital_object_component.display_string = t("default_values.form_title.digital_object_component")

    render "defaults"
  end


  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "digital_object_component",
                                "lock_version" => params[:digital_object_component].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:digital_object_component],
                                                                        JSONModel(:digital_object_component).schema
                                                                        )
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")

      redirect_to :controller => :digital_object_components, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :digital_object_components, :action => :defaults
    end
  end


  def rde
    flash.clear

    @parent = JSONModel(:digital_object_component).find(params[:id])
    @digital_object_uri = @parent['digital_object']['ref']
    @children = DigitalObjectComponentChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def validate_rows
    row_data = cleanup_params_for_schema(params[:digital_record_children], JSONModel(:digital_record_children).schema)

    # build the DOC record but don't bother validating it yet...
    do_children = DigitalObjectComponentChildren.from_hash(row_data, false, true)

    # validate each row individually (to avoid weird indexes in the error paths)
    render :json => do_children.children.collect {|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}
  end

  def add_children
    @parent = JSONModel(:digital_object_component).find(params[:id])
    @digital_object_uri = @parent['digital_object']['ref']

    if params[:digital_record_children].blank? or params[:digital_record_children]["children"].blank?

      @children = DigitalObjectComponentChildren.new
      flash.now[:error] = t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:digital_record_children], JSONModel(:digital_record_children).schema)

      begin
        @children = DigitalObjectComponentChildren.from_hash(children_data, false)

        if params["validate_only"] == "true"
          @exceptions = @children.children.collect {|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}

          error_count = @exceptions.select {|e| !e.empty?}.length
          if error_count > 0
            flash.now[:error] = t("rde.messages.rows_with_errors", :count => error_count)
          else
            flash.now[:success] = t("rde.messages.rows_no_errors")
          end

          return render_aspace_partial :partial => "shared/rde"
        else
          @children.save(:digital_object_component_id => @parent.id)
        end

        return render :plain => t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children.children.collect {|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}

        if @exceptions.all?(&:blank?)
          e.errors.each { |key, vals| flash.now[:error] = "#{key} : #{vals.join('<br/>')}" }
        else
          flash.now[:error] = t("rde.messages.rows_with_errors", :count => @exceptions.select {|e| !e.empty?}.length)
        end
      end

    end

    render_aspace_partial :partial => "shared/rde"
  end


  def suppress
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.set_suppressed(true)

    flash[:success] = t("digital_object_component._frontend.messages.suppressed", digital_object_component_display_string: digital_object_component.title)
    redirect_to(:controller => :digital_objects, :action => :show, :id => JSONModel(:digital_object).id_for(digital_object_component['digital_object']['ref']), :anchor => "tree::digital_object_component_#{params[:id]}")
  end


  def unsuppress
    digital_object_component = JSONModel(:digital_object_component).find(params[:id])
    digital_object_component.set_suppressed(false)

    flash[:success] = t("digital_object_component._frontend.messages.unsuppressed", digital_object_component_display_string: digital_object_component.title)
    redirect_to(:controller => :digital_objects, :action => :show, :id => JSONModel(:digital_object).id_for(digital_object_component['digital_object']['ref']), :anchor => "tree::digital_object_component_#{params[:id]}")
  end

end
