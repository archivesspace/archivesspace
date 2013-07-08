class DigitalObjectsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree],
                      "update_archival_record" => [:new, :edit, :create, :update, :publish, :accept_children],
                      "delete_archival_record" => [:delete],
                      "merge_archival_record" => [:merge],
                      "transfer_archival_record" => [:transfer]

  FIND_OPTS = ["subjects", "linked_agents", "linked_instances"]


  def index
    @search_data = Search.for_type(session[:repo_id], params[:include_components]==="true" ? ["digital_object", "digital_object_component"] : "digital_object", search_params.merge({"facet[]" => SearchResultData.DIGITAL_OBJECT_FACETS}))
  end


  def show
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)
      return render :partial => "digital_objects/show_inline"
    end

    @digital_object = JSONModel(:digital_object).find(params[:id])
  end


  def transfer
    handle_transfer(JSONModel(:digital_object))
  end


  def new
    @digital_object = JSONModel(:digital_object).new({:title => I18n.t("digital_object.title_default", :default => "")})._always_valid!

    return render :partial => "digital_objects/new" if params[:inline]
  end


  def edit
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      # only fetch the fully resolved record when rendering the full form
      @digital_object = JSONModel(:digital_object).find(params[:id], "resolve[]" => FIND_OPTS)
      return render :partial => "digital_objects/edit_inline"
    end

    @digital_object = JSONModel(:digital_object).find(params[:id])
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


  def accept_children
    handle_accept_children(JSONModel(:digital_object))
  end


  def merge
    handle_merge(JSONModel(:digital_object).uri_for(params[:id]),
                 params[:ref],
                 'digital_object')
  end


  def tree
    flash.keep # keep the flash... just in case this fires before the form is loaded

    render :json => fetch_tree
  end


  private

  def fetch_tree
    tree = {}

    limit_to = params[:node_uri] || "root"

    if !params[:hash].blank?
      node_id = params[:hash].sub("#tree::", "")
      if node_id.starts_with?("digital_object_component")
        limit_to = JSONModel(:digital_object_component).uri_for(node_id.sub("digital_object_component_", "").to_i)
      elsif node_id.starts_with?("digital_object")
        limit_to = "root"
      end
    end

    parse_tree(JSONModel(:digital_object_tree).find(nil, :digital_object_id => params[:id], :limit_to => limit_to).to_hash(:validated), nil) do |node, parent|
      node['level'] = I18n.t("enumerations.digital_object_level.#{node['level']}", :default => node['level']) if node['level']
      node['digital_object_type'] = I18n.t("enumerations.digital_object_digital_object_type.#{node['digital_object_type']}", :default => node['digital_object_type']) if node['digital_object_type']

      tree["#{node["node_type"]}_#{node["id"]}"] = node.merge("children" => node["children"].collect{|child| "#{child["node_type"]}_#{child["id"]}"})
    end

    tree
  end

end
