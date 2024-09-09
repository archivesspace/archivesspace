class ArchivalObjectsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :models_in_graph],
                      "update_resource_record" => [:new, :edit, :create, :update, :transfer, :rde, :add_children, :publish, :unpublish, :accept_children, :validate_rows],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]

  def new
    if params[:duplicate_from_archival_object]
      new_find_opts = find_opts
      new_find_opts["resolve[]"].push("top_container::container_locations")

      archival_object_id = params[:duplicate_from_archival_object][:uri].split('/').pop

      @archival_object = JSONModel(:archival_object).find(archival_object_id, new_find_opts)
      @archival_object.ref_id = nil
      @archival_object.instances = []
      @archival_object.position = params[:position]

      flash[:success] = t("archival_object._frontend.messages.duplicated", archival_object_display_string: @archival_object.display_string)
    else
      @archival_object = ArchivalObject.new._always_valid!
      @archival_object.parent = {'ref' => ArchivalObject.uri_for(params[:archival_object_id])} if params.has_key?(:archival_object_id)
      @archival_object.resource = {'ref' => Resource.uri_for(params[:resource_id])} if params.has_key?(:resource_id)
      @archival_object.position = params[:position]
      if defaults = user_defaults('archival_object')
        @archival_object.update(defaults.values)
      end

      if params[:accession_id]
        acc = Accession.find(params[:accession_id], find_opts)
        @archival_object.populate_from_accession(acc)

        flash.now[:info] = t("archival_object._frontend.messages.spawned", accession_display_string: acc.title)
        flash[:spawned_from_accession] = acc.id
      end
    end

    return render_aspace_partial :partial => "archival_objects/new_inline" if inline?
  end

  def edit
    new_find_opts = find_opts
    new_find_opts["resolve[]"].push("top_container::container_locations")

    @archival_object = JSONModel(:archival_object).find(params[:id], new_find_opts)

    if @archival_object.suppressed
      return redirect_to(:action => :show, :id => params[:id], :inline => params[:inline])
    end

    render_aspace_partial :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :find_opts => find_opts,
                :on_invalid => ->() {
                  if inline?
                    render_aspace_partial :partial => "new_inline"
                  else
                    render action: :new
                  end
                },
                :on_valid => ->(id) {

                  resource = @archival_object['resource']['_resolved']
                  parent = @archival_object['parent'] ? @archival_object['parent']['_resolved'] : false

                  success_message = @archival_object.parent ?
                                      t("archival_object._frontend.messages.created_with_parent", archival_object_display_string: @archival_object.title, parent_display_string: parent['title'], resource_title: resource['title']) :
                                      t("archival_object._frontend.messages.created", archival_object_display_string: @archival_object.title, resource_title: resource['title'])
                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  if @archival_object["is_slug_auto"] == false &&
                     @archival_object["slug"] == nil &&
                     params["archival_object"] &&
                     params["archival_object"]["is_slug_auto"] == "1"

                    if params.has_key?(:plus_one)
                      flash[:warning] = t("slug.autogen_disabled")
                    else
                      flash.now[:warning] = t("slug.autogen_disabled")
                    end
                  end
                  if inline?
                    render_aspace_partial :partial => "archival_objects/edit_inline"
                  else
                    id = ArchivalObject.id_for(@archival_object.uri)
                    resource_id = Resource.id_for(@archival_object.resource['ref'])
                    redirect_to controller: :resources, action: :edit, id: resource_id, anchor: "tree::archival_object_#{id}"
                  end
                })
  end


  def update
    params['archival_object']['position'] = params['archival_object']['position'].to_i if params['archival_object']['position']

    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)
    resource = @archival_object['resource']['_resolved']
    parent = @archival_object['parent'] ? @archival_object['parent']['_resolved'] : false
    handle_crud(:instance => :archival_object,
                :obj => @archival_object,
                :on_invalid => ->() { return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id) {

                  flash_success = parent ?
                    t("archival_object._frontend.messages.updated_with_parent", archival_object_display_string: @archival_object.title) :
                    t("archival_object._frontend.messages.updated", archival_object_display_string: @archival_object.title)
                  flash.now[:success] = flash_success
                  if @archival_object["is_slug_auto"] == false &&
                     @archival_object["slug"] == nil &&
                     params["archival_object"] &&
                     params["archival_object"]["is_slug_auto"] == "1"

                    flash.now[:warning] = t("slug.autogen_disabled")
                  end

                  render_aspace_partial :partial => "edit_inline"
                })
  end

  def current_record
    @archival_object
  end

  def show
    @resource_id = params['resource_id']

    new_find_opts = find_opts
    new_find_opts["resolve[]"].push("top_container::container_locations")

    @archival_object = JSONModel(:archival_object).find(params[:id], new_find_opts)

    flash.now[:info] = t("archival_object._frontend.messages.suppressed_info") if @archival_object.suppressed

    render_aspace_partial :partial => "archival_objects/show_inline" if inline?
  end


  def accept_children
    handle_accept_children(JSONModel(:archival_object))
  end


  def defaults
    defaults = DefaultValues.get 'archival_object'

    values = defaults ? defaults.form_values : {}

    @archival_object = JSONModel(:archival_object).new(values)._always_valid!

    @archival_object.display_string = t("default_values.form_title.archival_object")

    render "defaults"
  end


  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "archival_object",
                                "lock_version" => params[:archival_object].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:archival_object],
                                                                        JSONModel(:archival_object).schema
                                                                        )
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :archival_objects, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :archival_objects, :action => :defaults
    end
  end


  def transfer
    begin
      post_data = {
        :target_resource => params["transfer"]["ref"],
        :component => JSONModel(:archival_object).uri_for(params[:id])
      }

      response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/component_transfers", post_data)

      if response.code == '200'
        @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)
        resource = @archival_object['resource']['_resolved']
        flash[:success] = t("archival_object._frontend.messages.transfer_success", archival_object_display_string: @archival_object.title, resource_title: resource['title'])
        redirect_to :controller => :resources, :action => :edit, :id => JSONModel(:resource).id_for(params["transfer"]["ref"]), :anchor => "tree::archival_object_#{params[:id]}"
      else
        raise ASUtils.json_parse(response.body)['error'].to_s
      end

    rescue Exception => e
      flash[:error] = t("archival_object._frontend.messages.transfer_error", :exception => e)
      redirect_to :controller => :resources, :action => :edit, :id => params["transfer"]["current_resource_id"], :anchor => "tree::archival_object_#{params[:id]}"
    end
  end


  def delete
    archival_object = JSONModel(:archival_object).find(params[:id])

    previous_record = begin
      JSONModel::HTTP.get_json("#{archival_object['uri']}/previous")
    rescue RecordNotFound
      nil
    end
    begin
      archival_object.delete
    rescue ConflictException => e
      flash[:error] = t("archival_object._frontend.messages.delete_conflict", :error => t("errors.#{e.conflicts}", :default => e.message))
      resolver = Resolver.new(archival_object['uri'])
      return redirect_to resolver.view_uri
    end

    flash[:success] = t("archival_object._frontend.messages.deleted", archival_object_display_string: archival_object.title)

    if previous_record
      redirect_to :controller => :resources, :action => :show, :id => JSONModel(:resource).id_for(archival_object['resource']['ref']), :anchor => "tree::archival_object_#{JSONModel(:archival_object).id_for(previous_record['uri'])}"
    else
      # no previous node, so redirect to the resource
      resolver = Resolver.new(archival_object['resource']['ref'])
      redirect_to resolver.view_uri
    end
  end


  def rde
    @parent = JSONModel(:archival_object).find(params[:id])
    @resource_uri = @parent['resource']['ref']
    @children = ArchivalObjectChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def add_children
    @parent = JSONModel(:archival_object).find(params[:id])
    @resource_uri = @parent['resource']['ref']

    if params[:archival_record_children].blank? or params[:archival_record_children]["children"].blank?

      @children = ArchivalObjectChildren.new
      flash.now[:error] = t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

      begin
        @children = ArchivalObjectChildren.from_hash(children_data, false)

        if params["validate_only"] == "true"
          @exceptions = @children.children.collect {|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

          error_count = @exceptions.select {|e| !e.empty?}.length
          if error_count > 0
            flash.now[:error] = t("rde.messages.rows_with_errors", :count => error_count)
          else
            flash.now[:success] = t("rde.messages.rows_no_errors")
          end

          return render_aspace_partial :partial => "shared/rde"
        else
          @children.save(:archival_object_id => @parent.id)
        end

        return render :plain => t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children.children.collect {|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

        if @exceptions.all?(&:blank?)
          e.errors.each { |key, vals| flash.now[:error] = "#{key} : #{vals.join('<br/>')}" }
        else
          flash.now[:error] = t("rde.messages.rows_with_errors", :count => @exceptions.select {|e| !e.empty?}.length)
        end
      end

    end

    render_aspace_partial :partial => "shared/rde"
  end


  def publish
    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)

    response = JSONModel::HTTP.post_form("#{@archival_object.uri}/publish")

    if response.code == '200'
      flash[:success] = t("archival_object._frontend.messages.published", archival_object_title: @archival_object.title)
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to "#{request.referer}#tree::archival_object_#{params[:id]}"
  end


  def unpublish
    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)

    response = JSONModel::HTTP.post_form("#{@archival_object.uri}/unpublish")

    if response.code == '200'
      flash[:success] = t("archival_object._frontend.messages.unpublished", archival_object_title: @archival_object.title)
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to "#{request.referer}#tree::archival_object_#{params[:id]}"
  end


  def validate_rows
    row_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

    # build the AOC record but don't bother validating it yet...
    aoc = ArchivalObjectChildren.from_hash(row_data, false, true)

    # validate each row individually (to avoid weird indexes in the error paths)
    render :json => aoc.children.collect {|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}
  end


  def suppress
    archival_object = JSONModel(:archival_object).find(params[:id])
    archival_object.set_suppressed(true)

    flash[:success] = t("archival_object._frontend.messages.suppressed", archival_object_title: archival_object.title)
    redirect_to(:controller => :resources, :action => :show, :id => JSONModel(:resource).id_for(archival_object['resource']['ref']), :anchor => "tree::archival_object_#{params[:id]}")
  end


  def unsuppress
    archival_object = JSONModel(:archival_object).find(params[:id])
    archival_object.set_suppressed(false)

    flash[:success] = t("archival_object._frontend.messages.unsuppressed", archival_object_title: archival_object.title)
    redirect_to(:controller => :resources, :action => :show, :id => JSONModel(:resource).id_for(archival_object['resource']['ref']), :anchor => "tree::archival_object_#{params[:id]}")
  end


  def models_in_graph
    list_uri = JSONModel(:archival_object).uri_for(params[:id]) + "/models_in_graph"
    list = JSONModel::HTTP.get_json(list_uri)

    render :json => list.select { |type| type != "lang_material" }.map {|type|
      [type, t("#{type == 'archival_object' ? 'resource_component' : type}._singular")]
    }
  end
end
