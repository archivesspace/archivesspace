class ResourcesController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree_root, :tree_node, :tree_waypoint, :node_from_root, :models_in_graph],
                      "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children],
                      "delete_archival_record" => [:delete],
                      "merge_archival_record" => [:merge],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "transfer_archival_record" => [:transfer],
                      "manage_repository" => [:defaults, :update_defaults]


  include ExportHelper

  def index
    respond_to do |format| 
      format.html {   
        @search_data = Search.for_type(session[:repo_id], params[:include_components]==="true" ? ["resource", "archival_object"] : "resource", params_for_backend_search.merge({"facet[]" => SearchResultData.RESOURCE_FACETS}))
      }
      format.csv { 
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.RESOURCE_FACETS})
        search_params["type[]"] = params[:include_components] === "true" ? ["resource", "archival_object"] : [ "resource" ] 
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }  
    end 
  end

  def show
    flash.keep

    if params[:inline]
      @resource = fetch_resolved(params[:id])

      flash.now[:info] = I18n.t("resource._frontend.messages.suppressed_info", JSONModelI18nWrapper.new(:resource => @resource).enable_parse_mixed_content!(url_for(:root))) if @resource.suppressed
      return render_aspace_partial :partial => "resources/show_inline"
    end

    @resource = JSONModel(:resource).find(params[:id])
  end

  def new
    @resource = Resource.new(:title => I18n.t("resource.title_default", :default => ""))._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id], find_opts)

      if acc
        @resource.populate_from_accession(acc)
        flash.now[:info] = I18n.t("resource._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => acc).enable_parse_mixed_content!(url_for(:root)))
        flash[:spawned_from_accession] = acc.id
      end

    elsif user_prefs['default_values']
      defaults = DefaultValues.get 'resource'

      if defaults
        @resource.update(defaults.values)
        @form_title = "#{I18n.t('actions.new_prefix')} #{I18n.t('resource._singular')}"
      end

    end

    return render_aspace_partial :partial => "resources/new_inline" if params[:inline]
  end


  def defaults
    defaults = DefaultValues.get 'resource'

    values = defaults ? defaults.form_values : {:title => I18n.t("resource.title_default", :default => "")}

    @resource = Resource.new(values)._always_valid!

    @form_title = I18n.t("default_values.form_title.resource")


    render "defaults"
  end


  def update_defaults

    begin
      DefaultValues.from_hash({
                                "record_type" => "resource",
                                "lock_version" => params[:resource].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:resource], 
                                                                        JSONModel(:resource).schema
                                                                        )
                              }).save

      flash[:success] = "Defaults updated"

      redirect_to :controller => :resources, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :resources, :action => :defaults
    end

  end

  def tree_root
    resource_uri = JSONModel(:resource).uri_for(params[:id])

    render :json => pass_through_json("#{resource_uri}/tree/root")
  end

  def node_from_root
    resource_uri = JSONModel(:resource).uri_for(params[:id])

    render :json => pass_through_json("#{resource_uri}/tree/node_from_root",
                                      'node_ids[]' => params[:node_ids])
  end

  def tree_node
    resource_uri = JSONModel(:resource).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => pass_through_json("#{resource_uri}/tree/node",
                                      :node_uri => node_uri)
  end

  def tree_waypoint
    resource_uri = JSONModel(:resource).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => pass_through_json("#{resource_uri}/tree/waypoint",
                                      :parent_node => node_uri,
                                      :offset => params[:offset])

  end

  def transfer
    begin
      handle_transfer(Resource)
    rescue ArchivesSpace::TransferConflictException => e
      @transfer_errors = e.errors
      show
      render :action => :show
    end
  end


  def edit
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @resource = fetch_resolved(params[:id])

      if @resource.suppressed
        return redirect_to(:action => :show, :id => params[:id], :inline => params[:inline])
      end

      return render_aspace_partial :partial => "resources/edit_inline"
    end

    @resource = JSONModel(:resource).find(params[:id])
  end


  def create
    flash.keep(:spawned_from_accession)

    handle_crud(:instance => :resource,
                :on_invalid => ->(){
                  render action: "new"
                },
                :on_valid => ->(id){
                  redirect_to({
                                :controller => :resources,
                                :action => :edit,
                                :id => id
                              },
                              :flash => {:success => I18n.t("resource._frontend.messages.created", JSONModelI18nWrapper.new(:resource => @resource).enable_parse_mixed_content!(url_for(:root)))})
                 })
  end


  def update
    handle_crud(:instance => :resource,
                :obj => fetch_resolved(params[:id]),
                :on_invalid => ->(){
                  render_aspace_partial :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  flash.now[:success] = I18n.t("resource._frontend.messages.updated", JSONModelI18nWrapper.new(:resource => @resource).enable_parse_mixed_content!(url_for(:root)))
                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def delete
    resource = Resource.find(params[:id])

    begin
      resource.delete
    rescue ConflictException => e
      flash[:error] = I18n.t("resource._frontend.messages.delete_conflict", :error => I18n.t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :resources, :action => :show, :id => params[:id])
    end


    flash[:success] = I18n.t("resource._frontend.messages.deleted", JSONModelI18nWrapper.new(:resource => resource).enable_parse_mixed_content!(url_for(:root)))
    redirect_to(:controller => :resources, :action => :index, :deleted_uri => resource.uri)
  end


  def rde
    flash.clear

    @parent = Resource.find(params[:id])
    @resource_uri = @parent.uri
    @children = ResourceChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def add_children
    @parent = Resource.find(params[:id])
    @resource_uri = @parent.uri

    if params[:archival_record_children].blank? or params[:archival_record_children]["children"].blank?

      @children = ResourceChildren.new
      flash.now[:error] = I18n.t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

      begin
        @children = ResourceChildren.from_hash(children_data, false)

        if params["validate_only"] == "true"
          @exceptions = @children.children.collect{|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

          error_count = @exceptions.select{|e| !e.empty?}.length
          if error_count > 0
            flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => error_count)
          else
            flash.now[:success] = I18n.t("rde.messages.rows_no_errors")
          end

          return render_aspace_partial :partial => "shared/rde"
        else
          @children.save(:resource_id => @parent.id)
        end

        return render :text => I18n.t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children.children.collect{|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

        flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => @exceptions.select{|e| !e.empty?}.length)
      end

    end

    render_aspace_partial :partial => "shared/rde"
  end


  def publish
    resource = Resource.find(params[:id])

    response = JSONModel::HTTP.post_form("#{resource.uri}/publish")

    if response.code == '200'
      flash[:success] = I18n.t("resource._frontend.messages.published", JSONModelI18nWrapper.new(:resource => resource).enable_parse_mixed_content!(url_for(:root)))
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to request.referer
  end


  def accept_children
    handle_accept_children(JSONModel(:resource))
  end


  def merge
    handle_merge( params[:refs],
                  JSONModel(:resource).uri_for(params[:id]),
                  'resource')
  end


  def suppress
    resource = JSONModel(:resource).find(params[:id])
    resource.set_suppressed(true)

    flash[:success] = I18n.t("resource._frontend.messages.suppressed", JSONModelI18nWrapper.new(:resource => resource).enable_parse_mixed_content!(url_for(:root)))
    redirect_to(:controller => :resources, :action => :show, :id => params[:id])
  end


  def unsuppress
    resource = JSONModel(:resource).find(params[:id])
    resource.set_suppressed(false)

    flash[:success] = I18n.t("resource._frontend.messages.unsuppressed", JSONModelI18nWrapper.new(:resource => resource).enable_parse_mixed_content!(url_for(:root)))
    redirect_to(:controller => :resources, :action => :show, :id => params[:id])
  end


  def models_in_graph
    list_uri = JSONModel(:resource).uri_for(params[:id]) + "/models_in_graph"
    list = JSONModel::HTTP.get_json(list_uri)

    render :json => list.map {|type|
      [type, I18n.t("#{type == 'archival_object' ? 'resource_component' : type}._singular")]
    }
  end

  private


  def pass_through_json(uri, params = {})
    json = "{}"

    JSONModel::HTTP.stream(uri, params) do |response|
      json = response.body
    end

    json
  end


# refactoring note: suspiciously similar to accessions_controller.rb
  def fetch_resolved(id)
    resource = JSONModel(:resource).find(id, find_opts)

    if resource['classifications'] 
      resource['classifications'].each do |classification|
        next unless classification['_resolved']
        resolved = classification["_resolved"] 
        resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
      end 
    end

    resource
  end


end
