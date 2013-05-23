class ResourcesController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :delete, :rde, :add_children, :publish]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :rde, :add_children, :publish]) {|c| user_must_have("update_archival_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  FIND_OPTS = ["subjects", "container_locations", "related_accessions", "linked_agents", "digital_object", "classification"]

  def index
    @search_data = Search.for_type(session[:repo_id], "resource", search_params.merge({"facet[]" => SearchResultData.RESOURCE_FACETS}))
  end

  def show
    @resource = fetch_resource(params[:id])

    if params[:inline]
      return render :partial => "resources/show_inline"
    end

    flash.keep
    fetch_tree
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


  def edit
    @resource = fetch_resource(params[:id])

    fetch_tree
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call
    return render :partial => "resources/edit_inline" if params[:inline]
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
                :obj => fetch_resource(params[:id]),
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
      flash.now[:error] = "No rows entered"

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



  private

  def fetch_tree
    @tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id)
    parse_tree(@tree, proc {|node| node['level'] = I18n.t("enumerations.archival_record_level.#{node['level']}", :default => node['level'])})
  end


  def fetch_resource(id)
    resource = JSONModel(:resource).find(id, "resolve[]" => FIND_OPTS)

    if resource['classification'] && resource['classification']['_resolved']
      resolved = resource['classification']['_resolved']
      resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
    end

    resource
  end

end
