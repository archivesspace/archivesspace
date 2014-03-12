class ClassificationsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree],
                      "update_classification_record" => [:new, :edit, :create, :update, :accept_children],
                      "delete_classification_record" => [:delete]


  def index
    @search_data = Search.for_type(session[:repo_id], "classification", params_for_backend_search.merge({"facet[]" => SearchResultData.CLASSIFICATION_FACETS}))
  end

  def show
    flash.keep

    if params[:inline]
      @classification = JSONModel(:classification).find(params[:id], find_opts)
      return render_aspace_partial :partial => "classifications/show_inline"
    end

    @classification = JSONModel(:classification).find(params[:id])
  end

  def new
    @classification = JSONModel(:classification).new(:title => I18n.t("classification.title_default", :default => ""))._always_valid!

    return render_aspace_partial :partial => "classifications/new_inline" if params[:inline]
  end


  def edit
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call

    if params[:inline]
      @classification = JSONModel(:classification).find(params[:id], find_opts)
      return render_aspace_partial :partial => "classifications/edit_inline"
    end

    @classification = JSONModel(:classification).find(params[:id])
  end


  def create
    flash.keep(:spawned_from_accession)

    handle_crud(:instance => :classification,
                :on_invalid => ->(){
      render action: "new"
    },
      :on_valid => ->(id){
      redirect_to({
                    :controller => :classifications,
                    :action => :edit,
                    :id => id
                  },
                  :flash => {:success => I18n.t("classification._frontend.messages.created", JSONModelI18nWrapper.new(:classification => @classification))})
    })
  end


  def update
    handle_crud(:instance => :classification,
                :obj => JSONModel(:classification).find(params[:id], find_opts),
                :on_invalid => ->(){
      render_aspace_partial :partial => "edit_inline"
    },
      :on_valid => ->(id){
      @refresh_tree_node = true
    flash.now[:success] = I18n.t("classification._frontend.messages.updated", JSONModelI18nWrapper.new(:classification => @classification))
    render_aspace_partial :partial => "edit_inline"
    })
  end


  def delete
    classification = JSONModel(:classification).find(params[:id])
    classification.delete

    flash[:success] = I18n.t("classification._frontend.messages.deleted", JSONModelI18nWrapper.new(:classification => classification))
    redirect_to(:controller => :classifications, :action => :index, :deleted_uri => classification.uri)
  end


  def accept_children
    handle_accept_children(JSONModel(:classification))
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
      node_id = params[:hash].sub("tree::", "").sub("#", "")
      if node_id.starts_with?("classification_term")
        limit_to = JSONModel(:classification_term).uri_for(node_id.sub("classification_term_", "").to_i)
      elsif node_id.starts_with?("classification")
        limit_to = "root"
      end
    end

    parse_tree(JSONModel(:classification_tree).find(nil, :classification_id => params[:id], :limit_to => limit_to).to_hash(:validated), nil) do |node, parent|
      tree["#{node["node_type"]}_#{node["id"]}"] = node.merge("children" => node["children"].collect{|child| "#{child["node_type"]}_#{child["id"]}"})
    end

    tree
  end

end
