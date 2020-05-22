require 'uri'
require 'barcode_check'
require 'advanced_query_builder'

class TopContainersController < ApplicationController

  set_access_control  "view_repository" => [:bulk_operations_browse, :bulk_operation_search, :index, :show, :typeahead],
                      "update_container_record" => [:new, :create, :edit, :update],
                      "manage_container_record" => [:delete, :batch_delete, :batch_merge, :bulk_operations, :bulk_operation_update, :update_barcodes, :update_locations]


  def index
  end


  def new
    @top_container = JSONModel(:top_container).new._always_valid!

    if inline?
      render_aspace_partial(:partial => "top_containers/new",
                            :locals => {
                              :small => params[:small],
                              :created_for_collection => params[:created_for_collection]
                            })
    end
  end


  def create
    handle_crud(:instance => :top_container,
                :model => JSONModel(:top_container),
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "top_containers/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    @top_container.refetch
                    render :json => @top_container.to_hash if inline?
                  else
                    flash[:success] = I18n.t("top_container._frontend.messages.created")
                    redirect_to :controller => :top_containers, :action => :show, :id => id
                  end
                })
  end


  def show
    @top_container = JSONModel(:top_container).find(params[:id], find_opts)
  end


  def edit
    @top_container = JSONModel(:top_container).find(params[:id], find_opts)
  end


  def update
    handle_crud(:instance => :top_container,
                :model => JSONModel(:top_container),
                :obj => JSONModel(:top_container).find(params[:id], find_opts),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("top_container._frontend.messages.updated")
                  redirect_to :controller => :top_containers, :action => :show, :id => id
                })
  end


  def batch_merge
      merge_list = params[:victims]
      target = params[:target]
      victims = merge_list - target
      handle_merge( victims,
                    target[0],
                    'top_container')
  end


  def delete
    top_container = JSONModel(:top_container).find(params[:id])
    top_container.delete

    redirect_to(:controller => :top_containers, :action => :index, :deleted_uri => top_container.uri)
  end

  def batch_delete
    response = JSONModel::HTTP.post_form("/batch_delete",
                                         {
                                "record_uris[]" => Array(params[:record_uris])
                                         })

    if response.code === "200"
      flash[:success] = I18n.t("top_container.batch_delete.success")
      deleted_uri_param = params[:record_uris].map{|uri| "deleted_uri[]=#{uri}"}.join("&")
      redirect_to "#{request.referrer}?#{deleted_uri_param}"
    else
      flash[:error] = "#{I18n.t("top_container.batch_delete.error")}<br/> #{ASUtils.json_parse(response.body)["error"]["failures"].map{|err| "#{err["response"]} [#{err["uri"]}]"}.join("<br/>")}".html_safe
      redirect_to request.referrer
    end
  end


  def typeahead
    search_params = params_for_backend_search
    search_params["q"] = "*" + search_params["q"].gsub(/[^0-9A-Za-z]/, '').downcase + "*"

    search_params["q"] = "top_container_u_typeahead_utext:#{search_params["q"]}"

    search_params = search_params.merge(search_filter_for(params[:uri]))
    search_params = search_params.merge("sort" => "top_container_u_icusort asc")

    render :json => Search.all(session[:repo_id], search_params)
  end


  class MissingFilterException < Exception; end


  def bulk_operation_search
    begin
      results = perform_search
    rescue MissingFilterException
      return render :text => I18n.t("top_container._frontend.messages.filter_required"), :status => 500
    end

    render_aspace_partial :partial => "top_containers/bulk_operations/results", :locals => {:results => results}
  end


  def bulk_operations_browse
    begin
      results = perform_search if params.has_key?("q")
    rescue MissingFilterException
      flash[:error] = I18n.t("top_container._frontend.messages.filter_required")
    end

    render_aspace_partial :partial => "top_containers/bulk_operations/browse", :locals => {:results => results}
  end


  def bulk_operation_update
    post_params = {'ids[]' => params['update_uris'].map {|uri| JSONModel(:top_container).id_for(uri)}}
    post_uri = "/repositories/#{session[:repo_id]}/top_containers/batch/"

    if params['ils_holding_id']
      post_params['ils_holding_id'] = params['ils_holding_id']
      post_uri += 'ils_holding_id'
    elsif params['container_profile_uri']
      post_params['container_profile_uri'] = params['container_profile'] ? params['container_profile']['ref'] : ""
      post_uri += 'container_profile'
    elsif params['location_uri']
      post_params['location_uri'] = params['location'] ? params['location']['ref'] : ""
      post_uri += 'location'
    else
      render :text => "You must provide a field to update.", :status => 500
    end

    response = JSONModel::HTTP::post_form(post_uri, post_params)
    result = ASUtils.json_parse(response.body)

    if result.has_key?('records_updated')
      render_aspace_partial :partial => "top_containers/bulk_operations/bulk_action_success", :locals => {:result => result}
    else
      render :text => "There seems to have been a problem with the update: #{result['error']}", :status => 500
    end
  end


  def update_barcodes
    update_uris = params[:update_uris]
    barcode_data = {}
    update_uris.map{|uri| barcode_data[uri] = params[uri].blank? ? nil : params[uri]}

    post_uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/top_containers/bulk/barcodes"

    response = JSONModel::HTTP::post_json(URI(post_uri), barcode_data.to_json)
    result = ASUtils.json_parse(response.body)

    if response.code =~ /^4/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages', :locals => {:exceptions => result, :jsonmodel => "top_container"}, :status => 500
    end

    render_aspace_partial :partial => "top_containers/bulk_operations/bulk_action_success", :locals => {:result => result}
  end


  def update_locations
    update_uris = params[:update_uris]
    location_data = {}
    update_uris.map{|uri| location_data[uri] = params[uri].blank? ? nil : params[uri]['ref']}

    post_uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/top_containers/bulk/locations"

    response = JSONModel::HTTP::post_json(URI(post_uri), location_data.to_json)
    result = ASUtils.json_parse(response.body) rescue nil

    if response.code =~ /^4/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages',
				   :locals => {:exceptions => (result || response.message),
					       :jsonmodel => "top_container"},
				   :status => 500
    elsif response.code =~ /^5/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages',
				   :locals => {:exceptions => response.message},
				   :status => 500
    end

    render_aspace_partial :partial => "top_containers/bulk_operations/bulk_action_success", :locals => {:result => result}
  end


  private

  helper_method :can_edit_search_result?
  def can_edit_search_result?(record)
    return user_can?('update_container_record') if record['primary_type'] === "top_container"
    SearchHelper.can_edit_search_result?(record)
  end


  include ApplicationHelper

  helper_method :barcode_length_range
  def barcode_length_range
    check = BarcodeCheck.new(current_repo[:repo_code])
    check.min == check.max ? check.min.to_s : "#{check.min}-#{check.max}"
  end


  def search_filter_for(uri)
    return {} if uri.blank?

    # filter for containers in this collection
    # or that were created for this collection
    # if they are currently not associated with any collection
    # this is helpful in situations like RDE
    # where the top_container is created and should be linkable
    # to other records in the collection before any of them are saved

    created_for_query = AdvancedQueryBuilder.new
    created_for_query.and('created_for_collection_u_sstr', uri, 'text', true)
    created_for_query.and('collection_uri_u_sstr', '*', 'text', true, true)

    top_or_query = AdvancedQueryBuilder.new
    top_or_query.or('collection_uri_u_sstr', uri, 'text', true)
    top_or_query.or(created_for_query)

    return {
      'filter' => AdvancedQueryBuilder.new.and(top_or_query).build.to_json
    }
  end


  def perform_search
    search_params = params_for_backend_search.merge({
                                                      'type[]' => ['top_container']
                                                    })

    builder = AdvancedQueryBuilder.new

    if params['collection_resource']
      builder.and('collection_uri_u_sstr', params['collection_resource']['ref'], 'text', literal = true)
    end

    if params['collection_accession']
      builder.and('collection_uri_u_sstr', params['collection_accession']['ref'], 'text', literal = true)
    end

    if params['container_profile']
      builder.and('container_profile_uri_u_sstr', params['container_profile']['ref'], 'text', literal = true)
    end

    if params['location']
      builder.and('location_uri_u_sstr', params['location']['ref'], 'text', literal = true)
    end

    unless params['exported'].blank?
      builder.and('exported_u_sbool',
                  (params['exported'] == "yes" ? true : false),
                  'boolean')
    end

    unless params['empty'].blank?
      builder.and('empty_u_sbool', (params['empty'] == "yes" ? true : false), 'boolean')
    end

    unless params['has_location'].blank?
      builder.and('has_location_u_sbool', (params['has_location'] == "yes" ? true : false), 'boolean')
    end

    unless params['barcodes'].blank?
      barcode_query = AdvancedQueryBuilder.new

      ASUtils.wrap(params['barcodes'].split(" ")).each do |barcode|
        barcode_query.or('barcode_u_sstr', barcode)

        # Subcontainer string contains barcode
        barcode_query.or('subcontainer_barcodes_u_sstr', barcode)
      end

      unless barcode_query.empty?
        builder.and(barcode_query)
      end
    end

    if builder.empty? && params['q'].blank?
      raise MissingFilterException.new
    end

    unless builder.empty?
      search_params = search_params.merge({
                                            "filter" => builder.build.to_json,
                                          })
    end

    container_search_url = "#{JSONModel(:top_container).uri_for("")}/search"
    JSONModel::HTTP::get_json(container_search_url, search_params)
  end

end

