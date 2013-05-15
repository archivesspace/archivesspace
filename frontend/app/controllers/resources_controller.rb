class ResourcesController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :delete, :rde, :add_children]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :rde, :add_children]) {|c| user_must_have("update_archival_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  FIND_OPTS = ["subjects", "container_locations", "related_accessions", "linked_agents", "digital_object"]

  def index
    @search_data = Search.for_type(session[:repo_id], "resource", search_params.merge({"facet[]" => SearchResultData.RESOURCE_FACETS}))
  end

  def show
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => FIND_OPTS)

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
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => FIND_OPTS)

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
                :obj => JSONModel(:resource).find(params[:id],
                                                  "resolve[]" => FIND_OPTS),
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
    @parent = Resource.find(params[:id])
    @archival_object_children = ResourceChildren.new

    render :partial => "archival_objects/rde"
  end


  def add_children
    @parent = Resource.find(params[:id])

    children_data = cleanup_params_for_schema({"children" => params[:children]}, JSONModel(:archival_object_children).schema)

    begin
      @archival_object_children = ResourceChildren.from_hash(children_data)
    rescue JSONModel::ValidationException => e
      flash.now[:error] = e.inspect
    end

    @archival_object_children = ResourceChildren.from_hash(children_data, false, true) if @archival_object_children.nil?

    render :partial => "archival_objects/rde"
  end


  private

  def fetch_tree
    @tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id)
    parse_tree(@tree, proc {|node| node['level'] = I18n.t("enumerations.archival_record_level.#{node['level']}", :default => node['level'])})
  end

end
