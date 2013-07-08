class ResourcesController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree],
                      "update_archival_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children],
                      "delete_archival_record" => [:delete],
                      "merge_archival_record" => [:merge],
                      "transfer_archival_record" => [:transfer]

  FIND_OPTS = ["subjects", "container_locations", "related_accessions", "linked_agents", "digital_object", "classification"]


  def index
    @search_data = Search.for_type(session[:repo_id], params[:include_components]==="true" ? ["resource", "archival_object"] : "resource", search_params.merge({"facet[]" => SearchResultData.RESOURCE_FACETS}))
  end

  def show
    flash.keep

    if params[:inline]
      @resource = fetch_resolved(params[:id])
      return render :partial => "resources/show_inline"
    end

    @resource = JSONModel(:resource).find(params[:id])
  end

  def new
    @resource = Resource.new(:title => I18n.t("resource.title_default", :default => ""))._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id],
                           "resolve[]" => FIND_OPTS)

      if acc
        @resource.populate_from_accession(acc)
        flash.now[:info] = I18n.t("resource._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => acc))
        flash[:spawned_from_accession] = acc.id
      end
    end

    return render :partial => "resources/new_inline" if params[:inline]
  end


  def transfer
    handle_transfer(Resource)
  end


  def edit
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @resource = fetch_resolved(params[:id])
      return render :partial => "resources/edit_inline"
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
                              :flash => {:success => I18n.t("resource._frontend.messages.created", JSONModelI18nWrapper.new(:resource => @resource))})
                 })
  end


  def update
    handle_crud(:instance => :resource,
                :obj => fetch_resolved(params[:id]),
                :on_invalid => ->(){
                  render :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  @refresh_tree_node = true
                  flash.now[:success] = I18n.t("resource._frontend.messages.updated", JSONModelI18nWrapper.new(:resource => @resource))
                  render :partial => "edit_inline"
                })
  end


  def delete
    resource = Resource.find(params[:id])
    resource.delete

    flash[:success] = I18n.t("resource._frontend.messages.deleted", JSONModelI18nWrapper.new(:resource => resource))
    redirect_to(:controller => :resources, :action => :index, :deleted_uri => resource.uri)
  end


  def rde
    flash.clear

    @parent = Resource.find(params[:id])
    @archival_record_children = ResourceChildren.new

    render :partial => "archival_objects/rde"
  end


  def add_children
    @parent = Resource.find(params[:id])

    if params[:archival_record_children].blank? or params[:archival_record_children]["children"].blank?

      @archival_record_children = ResourceChildren.new
      flash.now[:error] = I18n.t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

      begin
        @archival_record_children = ResourceChildren.from_hash(children_data, false, true)
        @archival_record_children.save(:resource_id => @parent.id)

        return render :text => I18n.t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @archival_record_children._exceptions
      end

    end

    render :partial => "archival_objects/rde"
  end


  def publish
    resource = Resource.find(params[:id])

    response = JSONModel::HTTP.post_form("#{resource.uri}/publish")

    if response.code == '200'
      flash[:success] = I18n.t("resource._frontend.messages.published", JSONModelI18nWrapper.new(:resource => resource))
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to request.referer
  end


  def accept_children
    handle_accept_children(JSONModel(:resource))
  end


  def merge
    handle_merge(JSONModel(:resource).uri_for(params[:id]),
                 params[:ref],
                 'resource')
  end


  def tree
    render :json => fetch_tree
  end


  private

  def fetch_tree
    flash.keep # keep the flash... just in case this fires before the form is loaded

    tree = {}

    limit_to = params[:node_uri] || "root"

    if !params[:hash].blank?
      node_id = params[:hash].sub("#tree::", "")
      if node_id.starts_with?("resource")
        limit_to = "root"
      elsif node_id.starts_with?("archival_object")
        limit_to = JSONModel(:archival_object).uri_for(node_id.sub("archival_object_", "").to_i)
      end
    end

    parse_tree(JSONModel(:resource_tree).find(nil, :resource_id => params[:id], :limit_to => limit_to).to_hash(:validated), nil, proc {|node, parent|
      node['level'] = I18n.t("enumerations.archival_record_level.#{node['level']}", :default => node['level'])
      node['instance_types'] = node['instance_types'].map{|instance_type| I18n.t("enumerations.instance_instance_type.#{instance_type}", :default => instance_type)}
      node['containers'].each{|container|
        container["type_1"] = I18n.t("enumerations.container_type.#{container["type_1"]}", :default => container["type_1"]) if container["type_1"]
        container["type_2"] = I18n.t("enumerations.container_type.#{container["type_2"]}", :default => container["type_2"]) if container["type_2"]
        container["type_3"] = I18n.t("enumerations.container_type.#{container["type_3"]}", :default => container["type_3"]) if container["type_3"]
      }
      node['parent'] = "#{parent["node_type"]}_#{parent["id"]}" if parent
      tree["#{node["node_type"]}_#{node["id"]}"] = node.merge("children" => node["children"].collect{|child| "#{child["node_type"]}_#{child["id"]}"})
    })

    tree
  end


  # refactoring note: suspiciously similar to accessions_controller.rb
  def fetch_resolved(id)
    resource = JSONModel(:resource).find(id, "resolve[]" => FIND_OPTS)

    if resource['classification'] && resource['classification']['_resolved']
      resolved = resource['classification']['_resolved']
      resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
    end

    resource
  end

end
