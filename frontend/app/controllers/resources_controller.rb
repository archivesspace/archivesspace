class ResourcesController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_archival_record")}

  FIND_OPTS = ["subjects", "container_locations", "related_accessions", "linked_agents", "digital_object"]

  def index
    @search_data = JSONModel(:resource).all(:page => selected_page)
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
    @resource = Resource.new(:title => I18n.t("resource.title_default"))._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id],
                           "resolve[]" => FIND_OPTS)

      if acc
        @resource.populate_from_accession(acc)
        flash.now[:info] = "#{I18n.t("resource._html.messages.spawned")}: #{acc.title}"
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
                              :flash => {:success => I18n.t("resource._html.messages.created")})
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
                  flash.now[:success] = I18n.t("resource._html.messages.updated")
                  render :partial => "edit_inline"
                })
  end


  private

  def fetch_tree
    @tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id)
    parse_tree(@tree, proc {|node| node['level'] = I18n.t("#{node['node_type']}.level_#{node['level']}", :default => node['level'])})
  end

end
