class ClassificationsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :tree_root, :tree_node, :tree_waypoint, :node_from_root],
                      "update_classification_record" => [:new, :edit, :create, :update, :accept_children],
                      "delete_classification_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]

  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "classification", params_for_backend_search.merge({"facet[]" => SearchResultData.CLASSIFICATION_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.CLASSIFICATION_FACETS})
        search_params["type[]"] = "classification"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{t('classification._plural').downcase}." )
      }
    end
  end

  def current_record
    @classification
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
    @classification = JSONModel(:classification).new(:title => t("classification.title_default", :default => ""))._always_valid!

    if user_prefs['default_values']
      defaults = DefaultValues.get 'classification'
      @classification.update(defaults.values) if defaults
    end


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
                :on_invalid => ->() {
      render action: "new"
    },
      :on_valid => ->(id) {

      flash[:success] = t("classification._frontend.messages.created", classification_title: @classification.title)

      if @classification["is_slug_auto"] == false &&
          @classification["slug"] == nil &&
          params["classification"] &&
          params["classification"]["is_slug_auto"] == "1"

        flash[:warning] = t("slug.autogen_disabled")
      end

      redirect_to({
                  :controller => :classifications,
                  :action => :edit,
                  :id => id
                })
    })
  end


  def update
    handle_crud(:instance => :classification,
                :obj => JSONModel(:classification).find(params[:id], find_opts),
                :on_invalid => ->() {
      render_aspace_partial :partial => "edit_inline"
    },
      :on_valid => ->(id) {
      flash.now[:success] = t("classification._frontend.messages.updated", classification_title: @classification.title)

      if @classification["is_slug_auto"] == false &&
          @classification["slug"] == nil &&
          params["classification"] &&
          params["classification"]["is_slug_auto"] == "1"

        flash.now[:warning] = t("slug.autogen_disabled")
      end

      render_aspace_partial :partial => "edit_inline"
    })
  end


  def delete
    classification = JSONModel(:classification).find(params[:id])
    classification.delete

    flash[:success] = t("classification._frontend.messages.deleted", classification_title: classification.title)
    redirect_to(:controller => :classifications, :action => :index, :deleted_uri => classification.uri)
  end


  def defaults
    defaults = DefaultValues.get 'classification'

    values = defaults ? defaults.form_values : {}

    @classification = JSONModel(:classification).new(values)._always_valid!
    @form_title = t("default_values.form_title.classification")

    render "defaults"
  end

  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "classification",
                                "lock_version" => params[:classification].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:classification],
                                                                        JSONModel(:classification).schema)
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :classifications, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :classifications, :action => :defaults
    end
  end


  def accept_children
    handle_accept_children(JSONModel(:classification))
  end


  def tree
    flash.keep # keep the flash... just in case this fires before the form is loaded

    render :json => fetch_tree
  end

  def tree_root
    classification_uri = JSONModel(:classification).uri_for(params[:id])

    render :json => JSONModel::HTTP.get_json("#{classification_uri}/tree/root")
  end

  def node_from_root
    classification_uri = JSONModel(:classification).uri_for(params[:id])

    render :json => JSONModel::HTTP.get_json("#{classification_uri}/tree/node_from_root",
                                             'node_ids[]' => params[:node_ids])
  end

  def tree_node
    classification_uri = JSONModel(:classification).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => JSONModel::HTTP.get_json("#{classification_uri}/tree/node",
                                             :node_uri => node_uri)
  end

  def tree_waypoint
    classification_uri = JSONModel(:classification).uri_for(params[:id])
    node_uri = if !params[:node].blank?
                 params[:node]
               else
                 nil
               end

    render :json => JSONModel::HTTP.get_json("#{classification_uri}/tree/waypoint",
                                             :parent_node => node_uri,
                                             :offset => params[:offset])
  end


  private

  def fetch_tree
    flash.keep

    tree = []
    limit_to = if params[:node_uri] && !params[:node_uri].include?("/classifications/")
                 params[:node_uri]
               else
                 "root"
               end


    if !params[:hash].blank?
      node_id = params[:hash].sub("tree::", "").sub("#", "")
      if node_id.starts_with?("classification_term")
        limit_to = JSONModel(:classification_term).uri_for(node_id.sub("classification_term_", "").to_i)
      elsif node_id.starts_with?("classification")
        limit_to = "root"
      end
    end

    tree = JSONModel(:classification_tree).find(nil, :classification_id => params[:id], :limit_to => limit_to).to_hash(:validated)

    prepare_tree_nodes(tree) do |node|

      node['text'] = node['title']

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
