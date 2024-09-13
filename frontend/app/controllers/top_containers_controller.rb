require 'uri'
require 'barcode_check'
require 'advanced_query_builder'

class TopContainersController < ApplicationController

  set_access_control  'view_repository' => [:bulk_operations_browse, :bulk_operation_search, :index, :show, :typeahead],
                      'update_container_record' => [:new, :create, :edit, :update],
                      'manage_container_record' => [:delete, :batch_delete, :batch_merge, :bulk_operations, :bulk_operation_update, :update_barcodes, :update_indicators, :update_locations]

  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        # If there was a previous top_container search, we prepopulate the form with the filled-in linkers and a search is executed in top_containers.bulk.js
        @top_container_previous_search = {}

        if session[:top_container_previous_search] && session[:top_container_previous_search] != {}
          if session[:top_container_previous_search]['resource']
            @top_container_previous_search['resource'] = session[:top_container_previous_search]['resource']
            @top_container_previous_search['resource']['id'] = @top_container_previous_search['resource']['uri']
          end

          if session[:top_container_previous_search]['accession']
            @top_container_previous_search['accession'] = session[:top_container_previous_search]['accession']
            @top_container_previous_search['accession']['id'] = @top_container_previous_search['accession']['uri']
          end

          if session[:top_container_previous_search]['container_profile']
            @top_container_previous_search['container_profile'] = session[:top_container_previous_search]['container_profile']
            @top_container_previous_search['container_profile']['id'] = @top_container_previous_search['container_profile']['uri']
          end

          if session[:top_container_previous_search]['location']
            @top_container_previous_search['location'] = session[:top_container_previous_search]['location']
            @top_container_previous_search['location']['id'] = @top_container_previous_search['location']['uri']
          end
        end

        @search_data = Search.for_type(session[:repo_id], 'top_container',
                                       params_for_backend_search.merge('facet[]' => SearchResultData.TOP_CONTAINER_FACETS))
      }
      format.csv {
        params[:fields] -= %w[title context type indicator barcode]
        params[:fields] += %w[type_enum_s indicator_u_icusort barcode_u_sstr]
        params[:fields].prepend('collection_display_string_u_sstr', 'series_title_u_sstr')
        csv_response(
          "/repositories/#{session[:repo_id]}/search",
          prepare_search.merge('facet[]' => SearchResultData.TOP_CONTAINER_FACETS),
          "#{t('top_container._plural').downcase}."
        )
      }
    end
  end


  def new
    @top_container = JSONModel(:top_container).new._always_valid!

    if inline?
      render_aspace_partial(:partial => 'top_containers/new',
                            :locals => {
                              :small => params[:small],
                              :created_for_collection => params[:created_for_collection]
                            })
    end
  end


  def create
    handle_crud(:instance => :top_container,
                :model => JSONModel(:top_container),
                :on_invalid => ->() {
                  return render_aspace_partial :partial => 'top_containers/new' if inline?
                  return render :action => :new
                },
                :on_valid => ->(id) {
                  if inline?
                    @top_container.refetch
                    render :json => @top_container.to_hash if inline?
                  else
                    flash[:success] = t('top_container._frontend.messages.created')
                    redirect_to :controller => :top_containers, :action => :show, :id => id
                  end
                })
  end


  def current_record
    @top_container
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
                :on_invalid => ->() {
                  return render action: 'edit'
                },
                :on_valid => ->(id) {
                  flash[:success] = t('top_container._frontend.messages.updated')
                  redirect_to :controller => :top_containers, :action => :show, :id => id
                })
  end


  def batch_merge
    merge_list = params[:merge_candidates]
    merge_destination = params[:merge_destination]
    merge_candidates = merge_list - merge_destination
    handle_merge(merge_candidates,
                  merge_destination[0],
                  'top_container')
  end


  def delete
    top_container = JSONModel(:top_container).find(params[:id])
    top_container.delete

    redirect_to(:controller => :top_containers, :action => :index, :deleted_uri => top_container.uri)
  end

  def batch_delete
    response = JSONModel::HTTP.post_form('/batch_delete',
                                'record_uris[]' => Array(params[:record_uris])
                                         )

    if response.code === '200'
      flash[:success] = t('top_container.batch_delete.success')
      deleted_uri_param = params[:record_uris].map {|uri| "deleted_uri[]=#{uri}"}.join('&')
      redirect_to "#{request.referrer}?#{deleted_uri_param}"
    else
      flash[:error] = "#{t("top_container.batch_delete.error")}<br/> #{ASUtils.json_parse(response.body)["error"]["failures"].map {|err| "#{err["response"]} [#{err["uri"]}]"}.join("<br/>")}".html_safe
      redirect_to request.referrer
    end
  end


  def typeahead
    search_params = params_for_backend_search
    search_params['q'] = '*' + search_params['q'].gsub(/[^0-9A-Za-z]/, '').downcase + '*'

    search_params['q'] = "top_container_u_typeahead_utext:#{search_params["q"]}"

    search_params = search_params.merge(search_filter_for(params[:uri]))
    search_params = search_params.merge('sort' => 'top_container_u_icusort asc')

    render :json => Search.all(session[:repo_id], search_params)
  end


  class MissingFilterException < Exception; end


  def bulk_operation_search
    session[:top_container_previous_search] = {}

    # Store ONLY needed information from linkers in rails session so it can be repopulated for another search later
    # (The whole record is not saved because they are too big for the rails session and only a few pieces of info are used)
    if params['collection_resource']
      previous_resource = JSON.parse(params['collection_resource']['_resolved'])
      session[:top_container_previous_search]['resource'] = {
          'uri' => previous_resource['uri'],
          'title' => previous_resource['title'],
          'jsonmodel_type' => previous_resource['jsonmodel_type']
        }
    end

    if params['collection_accession']
      previous_accession = JSON.parse(params['collection_accession']['_resolved'])
      session[:top_container_previous_search]['accession'] = {
        'uri' => previous_accession['uri'],
        'title' => previous_accession['title'],
        'jsonmodel_type' => previous_accession['jsonmodel_type']
      }
    end

    if params['container_profile']
      previous_container_profile = JSON.parse(params['container_profile']['_resolved'])
      session[:top_container_previous_search]['container_profile'] = {
        'uri' => previous_container_profile['uri'],
        'title' => previous_container_profile['title'],
        'jsonmodel_type' => previous_container_profile['jsonmodel_type']
      }
    end

    if params['location']
      previous_location = JSON.parse(params['location']['_resolved'])
      session[:top_container_previous_search]['location'] = {
        'uri' => previous_location['uri'],
        'title' => previous_location['title'],
        'jsonmodel_type' => previous_location['jsonmodel_type']
      }
    end

    begin
      results = perform_search
    rescue MissingFilterException
      return render :plain => t('top_container._frontend.messages.filter_required'), :status => 500
    end

    get_browse_col_prefs
    render_aspace_partial :partial => 'top_containers/bulk_operations/results', :locals => {:results => results}
  end


  def bulk_operations_browse
    @top_container_previous_search = {}

    begin
      results = perform_search if params.has_key?('q')
    rescue MissingFilterException
      flash[:error] = t('top_container._frontend.messages.filter_required')
    end

    get_browse_col_prefs
    render_aspace_partial :partial => 'top_containers/bulk_operations/browse', :locals => {:results => results}
  end


  def get_browse_col_prefs
    # this sets things up to make the sortable table on this view work with the standard column prefs
    @pref_cols = browse_columns.select {|k, v| k.include? "top_container_mgmt_browse_column" }.values
    @default_sort_col = @pref_cols.find_index(browse_columns['top_container_mgmt_sort_column'])
    @default_sort_dir = browse_columns['top_container_mgmt_sort_direction'] == 'asc' ? 0 : 1
  end


  def bulk_operation_update
    post_params = {'ids[]' => params['update_uris'].map {|uri| JSONModel(:top_container).id_for(uri)}}
    post_uri = "/repositories/#{session[:repo_id]}/top_containers/batch/"

    if params['ils_holding_id']
      post_params['ils_holding_id'] = params['ils_holding_id']
      post_uri += 'ils_holding_id'
    elsif params['container_profile_uri']
      post_params['container_profile_uri'] = params['container_profile'] ? params['container_profile']['ref'] : ''
      post_uri += 'container_profile'
    elsif params['location_uri']
      post_params['location_uri'] = params['location'] ? params['location']['ref'] : ''
      post_uri += 'location'
    else
      render :plain => 'You must provide a field to update.', :status => 500
    end

    response = JSONModel::HTTP::post_form(post_uri, post_params)
    result = ASUtils.json_parse(response.body)

    if result.has_key?('records_updated')
      render_aspace_partial :partial => 'top_containers/bulk_operations/bulk_action_success', :locals => {:result => result}
    else
      render :plain => "There seems to have been a problem with the update: #{result['error']}", :status => 500
    end
  end


  def update_barcodes
    update_uris = params[:update_uris]
    barcode_data = {}
    update_uris.map {|uri| barcode_data[uri] = params[uri].blank? ? nil : params[uri]}

    post_uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/top_containers/bulk/barcodes"

    response = JSONModel::HTTP::post_json(URI(post_uri), barcode_data.to_json)
    result = ASUtils.json_parse(response.body)

    if response.code =~ /^4/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages', :locals => {:exceptions => result, :jsonmodel => 'top_container'}, :status => 500
    end

    render_aspace_partial :partial => 'top_containers/bulk_operations/bulk_action_success', :locals => {:result => result}
  end


  def update_indicators
    update_uris = params[:update_uris]
    indicator_data = {}
    update_uris.map {|uri| indicator_data[uri] = params[uri].blank? ? nil : params[uri]}

    post_uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/top_containers/bulk/indicators"

    response = JSONModel::HTTP::post_json(URI(post_uri), indicator_data.to_json)
    result = ASUtils.json_parse(response.body)

    if response.code =~ /^4/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages', :locals => {:exceptions => result, :jsonmodel => 'top_container'}, :status => 500
    end

    render_aspace_partial :partial => 'top_containers/bulk_operations/bulk_action_success', :locals => {:result => result}
  end


  def update_locations
    update_uris = params[:update_uris]
    location_data = {}
    update_uris.map {|uri| location_data[uri] = params[uri].blank? ? nil : params[uri]['ref']}

    post_uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/top_containers/bulk/locations"

    response = JSONModel::HTTP::post_json(URI(post_uri), location_data.to_json)
    result = ASUtils.json_parse(response.body) rescue nil

    if response.code =~ /^4/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages',
           :locals => {:exceptions => (result || response.message),
                 :jsonmodel => 'top_container'},
           :status => 500
    elsif response.code =~ /^5/
      return render_aspace_partial :partial => 'top_containers/bulk_operations/error_messages',
           :locals => {:exceptions => response.message},
           :status => 500
    end

    render_aspace_partial :partial => 'top_containers/bulk_operations/bulk_action_success', :locals => {:result => result}
  end


  private

  helper_method :can_edit_search_result?
  def can_edit_search_result?(record)
    return user_can?('update_container_record') if record['primary_type'] === 'top_container'
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
    JSONModel::HTTP::get_json("#{JSONModel(:top_container).uri_for("")}search", prepare_search)
  end

  # Gather all parameters, used for HTML and CSV responses
  def prepare_search
    search_params = params_for_backend_search.merge(
                                                      'type[]' => ['top_container']
                                                    )

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
                  (params['exported'] == 'yes' ? true : false),
                  'boolean')
    end

    unless params['empty'].blank?
      builder.and('empty_u_sbool', (params['empty'] == 'yes' ? true : false), 'boolean')
    end

    unless params['has_location'].blank?
      builder.and('has_location_u_sbool', (params['has_location'] == 'yes' ? true : false), 'boolean')
    end

    unless params['barcodes'].blank?
      barcode_query = AdvancedQueryBuilder.new

      ASUtils.wrap(params['barcodes'].split(' ')).each do |barcode|
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
      search_params = search_params.merge(
                                            'filter' => builder.build.to_json,
                                          )
    end

    search_params
  end

end
