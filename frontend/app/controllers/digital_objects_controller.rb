class DigitalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :tree, :new, :edit, :create, :update, :delete, :publish]
  before_filter(:only => [:index, :show, :tree]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :publish]) {|c| user_must_have("update_archival_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}


  FIND_OPTS = ["subjects", "linked_agents", "linked_instances"]

  def index
    @search_data = Search.for_type(session[:repo_id], "digital_object", search_params.merge({"facet[]" => SearchResultData.DIGITAL_OBJECT_FACETS}))
  end

  def show
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)

    if params[:inline]
      return render :partial => "digital_objects/show_inline"
    end

    fetch_tree
  end

  def new
    @digital_object = JSONModel(:digital_object).new({:title => I18n.t("digital_object.title_default", :default => "")})._always_valid!

    return render :partial => "digital_objects/new" if params[:inline]
  end

  def edit
    @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)

    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    return render :partial => "digital_objects/edit_inline" if params[:inline]

    fetch_tree
  end


  def create
    handle_crud(:instance => :digital_object,
                :on_invalid => ->(){
                  return render :partial => "new" if inline? 
                  render :action => "new" 
                },
                :on_valid => ->(id){
                  return render :json => @digital_object.to_hash if inline?
                  redirect_to({
                                :controller => :digital_objects,
                                :action => :edit,
                                :id => id
                              },
                              :flash => {:success => I18n.t("digital_object._frontend.messages.created", JSONModelI18nWrapper.new(:digital_object => @digital_object))})
                })
  end


  def update
    handle_crud(:instance => :digital_object,
                :obj => JSONModel(:digital_object).find(params[:id],
                                                  "resolve[]" => FIND_OPTS),
                :on_invalid => ->(){
                  render :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  @refresh_tree_node = true
                  flash.now[:success] = I18n.t("digital_object._frontend.messages.updated", JSONModelI18nWrapper.new(:digital_object => @digital_object))
                  render :partial => "edit_inline"
                })
  end


  def delete
    digital_object = JSONModel(:digital_object).find(params[:id])
    digital_object.delete

    flash[:success] = I18n.t("digital_object._frontend.messages.deleted", JSONModelI18nWrapper.new(:digital_object => digital_object))
    redirect_to(:controller => :digital_objects, :action => :index, :deleted_uri => digital_object.uri)
  end


  def publish
    digital_object = JSONModel(:digital_object).find(params[:id])

    response = JSONModel::HTTP.post_form("#{digital_object.uri}/publish")

    if response.code == '200'
      flash[:success] = I18n.t("digital_object._frontend.messages.published", JSONModelI18nWrapper.new(:digital_object => digital_object))
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to request.referer
  end


  private

  def fetch_tree
    @tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => @digital_object.id)
    parse_tree(@tree, proc {|node| node['level'] = I18n.t("enumerations.digital_object_level.#{node['level']}", :default => node['level']) if node['level']})
  end

end
