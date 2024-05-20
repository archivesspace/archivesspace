class DigitalObjectsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree_root, :tree_node, :tree_waypoint, :node_from_root],
                      "update_digital_object_record" => [:new, :edit, :create, :update, :publish, :accept_children, :rde, :add_children],
                      "delete_archival_record" => [:delete],
                      "merge_archival_record" => [:merge],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "transfer_archival_record" => [:transfer],
                      "manage_repository" => [:defaults, :update_defaults]

  include ExportHelper
  include NotesHelper
  include DigitalObjectHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], params[:include_components]==="true" ? ["digital_object", "digital_object_component"] : "digital_object", params_for_backend_search.merge({"facet[]" => SearchResultData.DIGITAL_OBJECT_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.DIGITAL_OBJECT_FACETS})
        search_params["type[]"] = params[:include_components] === "true" ? ["digital_object", "digital_object_component"] : [ "digital_object" ]
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{t('digital_object._plural').downcase}." )
      }
    end
  end


  def current_record
    @digital_object
  end


  def show
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @digital_object = JSONModel(:digital_object).find(params[:id], find_opts)

      flash.now[:info] = t("digital_object._frontend.messages.suppressed_info") if @digital_object.suppressed

      return render_aspace_partial :partial => "digital_objects/show_inline"
    end

    @digital_object = JSONModel(:digital_object).find(params[:id])
  end


  def transfer
    begin
      handle_transfer(JSONModel(:digital_object))
    rescue ArchivesSpace::TransferConflictException => e
      @transfer_errors = e.errors
      show
      render :action => :show
    end
  end


  def new
    @digital_object = JSONModel(:digital_object).new({:title => t("digital_object.title_default", :default => "")})._always_valid!

    if user_prefs['default_values']
      defaults = DefaultValues.get 'digital_object'

      if defaults
        @digital_object.update(defaults.values)
        @form_title = "#{t('actions.new_prefix')} #{t('digital_object._singular')}"
      end
    end

    if user_prefs['digital_object_spawn']
      if params[:spawn_from_resource_id]
        copy_from_record = Resource.find(params[:spawn_from_resource_id])
      elsif params[:spawn_from_accession_id]
        copy_from_record = Accession.find(params[:spawn_from_accession_id])
      elsif params[:spawn_from_archival_object_id]
        copy_from_record = ArchivalObject.find(params[:spawn_from_archival_object_id])
      end

      if copy_from_record
        updates = map_record_fields_to_digital_object(copy_from_record)
        @digital_object.update(updates)
      end
    end

    return render_aspace_partial :partial => "digital_objects/new" if params[:inline]
  end


  def defaults
    defaults = DefaultValues.get 'digital_object'

    values = defaults ? defaults.form_values : {:title => t("digital_object.title_default", :default => "")}

    @digital_object = JSONModel(:digital_object).new(values)._always_valid!

    @form_title = t("default_values.form_title.digital_object")

    render "defaults"
  end


  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "digital_object",
                                "lock_version" => params[:digital_object].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:digital_object],
                                                                        JSONModel(:digital_object).schema
                                                                        )
                              }).save

      flash[:success] = "Defaults updated"

      redirect_to :controller => :digital_objects, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :digital_objects, :action => :defaults
    end
  end


  def edit
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @digital_object = JSONModel(:digital_object).find(params[:id], find_opts)

      if @digital_object.suppressed
        return redirect_to(:action => :show, :id => params[:id], :inline => params[:inline])
      end

      return render_aspace_partial :partial => "digital_objects/edit_inline"
    end

    @digital_object = JSONModel(:digital_object).find(params[:id])
  end


  def create
    handle_crud(:instance => :digital_object,
                :on_invalid => ->() {
                  return render_aspace_partial :partial => "new" if inline?
                  render :action => "new"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("digital_object._frontend.messages.created", digital_object_title: @digital_object.title)

                  if @digital_object["is_slug_auto"] == false &&
                     @digital_object["slug"] == nil &&
                     params["digital_object"] &&
                     params["digital_object"]["is_slug_auto"] == "1"

                    flash[:warning] = t("slug.autogen_disabled")
                  end

                  return render :json => @digital_object.to_hash if inline?
                  redirect_to({
                                :controller => :digital_objects,
                                :action => :edit,
                                :id => id
                              })
                })
  end


  def update
    handle_crud(:instance => :digital_object,
                :obj => JSONModel(:digital_object).find(params[:id], find_opts),
                :on_invalid => ->() {
                  render_aspace_partial :partial => "edit_inline"
                },
                :on_valid => ->(id) {

                  flash.now[:success] = t("digital_object._frontend.messages.updated", digital_object_title: @digital_object.title)
                  if @digital_object["is_slug_auto"] == false &&
                     @digital_object["slug"] == nil &&
                     params["digital_object"] &&
                     params["digital_object"]["is_slug_auto"] == "1"

                    flash.now[:warning] = t("slug.autogen_disabled")
                  end

                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def delete
    digital_object = JSONModel(:digital_object).find(params[:id])

    begin
      digital_object.delete
    rescue ConflictException => e
      flash[:error] = t("digital_object._frontend.messages.delete_conflict", :error => t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :digital_objects, :action => :show, :id => params[:id])
    end

    flash[:success] = t("digital_object._frontend.messages.deleted", digital_object_title: digital_object.title)
    redirect_to(:controller => :digital_objects, :action => :index, :deleted_uri => digital_object.uri)
  end


  def publish
    digital_object = JSONModel(:digital_object).find(params[:id])

    response = JSONModel::HTTP.post_form("#{digital_object.uri}/publish")

    if response.code == '200'
      flash[:success] = t("digital_object._frontend.messages.published", digital_object_title: digital_object.title)
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to request.referer
  end


  def accept_children
    handle_accept_children(JSONModel(:digital_object))
  end


  def merge
    handle_merge( params[:refs] ,
                  JSONModel(:digital_object).uri_for(params[:id]),
                 'digital_object')
  end


  def tree
    flash.keep # keep the flash... just in case this fires before the form is loaded

    render :json => fetch_tree
  end


  def rde
    flash.clear

    @parent = JSONModel(:digital_object).find(params[:id])
    @digital_object_uri = @parent.uri
    @children = DigitalObjectChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def add_children
    @parent = JSONModel(:digital_object).find(params[:id])
    @digital_object_uri = @parent.uri

    if params[:digital_record_children].blank? or params[:digital_record_children]["children"].blank?

      @children = DigitalObjectChildren.new
      flash.now[:error] = t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:digital_record_children], JSONModel(:digital_record_children).schema)

      begin
        @children = DigitalObjectChildren.from_hash(children_data, false)

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
          @children.save(:digital_object_id => @parent.id)
        end

        return render :plain => t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children
                      .children
                      .collect {|c| JSONModel(:digital_object_component).from_hash(c, false)._exceptions}


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
    digital_object = JSONModel(:digital_object).find(params[:id])
    digital_object.set_suppressed(true)

    flash[:success] = t("digital_object._frontend.messages.suppressed", digital_object_title: digital_object.title)
    redirect_to(:controller => :digital_objects, :action => :show, :id => params[:id])
  end


  def unsuppress
    digital_object = JSONModel(:digital_object).find(params[:id])
    digital_object.set_suppressed(false)

    flash[:success] = t("digital_object._frontend.messages.unsuppressed", digital_object_title: digital_object.title)
    redirect_to(:controller => :digital_objects, :action => :show, :id => params[:id])
  end

  def tree_root
    digital_object_uri = JSONModel(:digital_object).uri_for(params[:id])

    render :json => JSONModel::HTTP.get_json("#{digital_object_uri}/tree/root")
  end

  def node_from_root
    digital_object_uri = JSONModel(:digital_object).uri_for(params[:id])

    render :json => JSONModel::HTTP.get_json("#{digital_object_uri}/tree/node_from_root",
                                             'node_ids[]' => params[:node_ids])
  end

  def tree_node
    digital_object_uri = JSONModel(:digital_object).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => JSONModel::HTTP.get_json("#{digital_object_uri}/tree/node",
                                             :node_uri => node_uri)
  end

  def tree_waypoint
    digital_object_uri = JSONModel(:digital_object).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => JSONModel::HTTP.get_json("#{digital_object_uri}/tree/waypoint",
                                             :parent_node => node_uri,
                                             :offset => params[:offset])
  end



  private

  def fetch_tree
    tree = {}

    limit_to = if params[:node_uri] && !params[:node_uri].include?("/digital_objects/")
                 params[:node_uri]
               else
                 "root"
               end

    if !params[:hash].blank?
      node_id = params[:hash].sub("tree::", "").sub("#", "")
      if node_id.starts_with?("digital_object_component")
        limit_to = JSONModel(:digital_object_component).uri_for(node_id.sub("digital_object_component_", "").to_i)
      elsif node_id.starts_with?("digital_object")
        limit_to = "root"
      end
    end

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => params[:id], :limit_to => limit_to).to_hash(:validated)

    prepare_tree_nodes(tree) do |node|

      node['text'] = node['title']
      node['level'] = t("enumerations.digital_object_level.#{node['level']}", :default => node['level']) if node['level']
      node['digital_object_type'] = t("enumerations.digital_object_digital_object_type.#{node['digital_object_type']}", :default => node['digital_object_type']) if node['digital_object_type']

      node_db_id = node['id']

      node['id'] = "#{node["node_type"]}_#{node["id"]}"

      if node['has_children'] && node['children'].empty?
        node['children'] = true
      end

      node['type'] = node['node_type']

      node['li_attr'] = {
        "data-uri" => node['record_uri'],
        "data-id" => node_db_id,
        "rel" => node['node_type']
      }
      node['a_attr'] = {
        "href" => "#tree::#{node['id']}",
        "title" => node["title"]
      }

    end

    tree
  end

end
