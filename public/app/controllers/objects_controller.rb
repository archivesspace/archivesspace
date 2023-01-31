class ObjectsController < ApplicationController
  include ResultInfo
  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents
  helper_method :process_digital
  helper_method :process_digital_instance

  skip_before_action  :verify_authenticity_token

  before_action(:only => [:show]) {
    process_slug_or_id(params)
  }

  DEFAULT_OBJ_FACET_TYPES = %w(repository primary_type subjects published_agents langcode)
  DEFAULT_OBJ_SEARCH_OPTS = {
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id'],
    'facet.mincount' => 1,
    'sort' =>  'title_sort asc'
  }

  def index
    repo_id = params.fetch(:rid, nil)
    if !params.fetch(:q, nil)
      params[:q] = ['*']
      params[:limit] = 'digital_object,archival_object' unless params.fetch(:limit, nil)
      params[:op] = ['OR']
    end
    search_opts = default_search_opts(DEFAULT_OBJ_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""] if repo_id
    search_opts['resolve[]'] = ['linked_instance_uris:id'] if params[:limit].include? 'digital_object'
    @base_search = repo_id ? "/repositories/#{repo_id}/objects?" : '/objects?'

    begin
      set_up_and_run_search( params[:limit].split(","), DEFAULT_OBJ_FACET_TYPES, search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/objects' ) and return
    end

    @context = repo_context(repo_id, 'record')
    if @results['total_hits'] > 1
      @search[:dates_within] = true if params.fetch(:filter_from_year, '').blank? && params.fetch(:filter_to_year, '').blank?
      @search[:text_within] = true
    end
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
      @sort_opts.push(all_sorts[type])
    end

    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'
  end

  def search
    @base_search = "/objects/search?"
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(%w(digital_object archival_object), DEFAULT_OBJ_FACET_TYPES, DEFAULT_OBJ_SEARCH_OPTS, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/objects' ) and return
    end
    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('record._plural'), :term => params.fetch(:q)[0]})
    @no_statement = true
    render 'search/search_results'
  end

  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    url = uri
    if params[:obj_type] == 'archival_objects'
      url = uri += '#pui' if !uri.ends_with?('#pui')
    end
    uri = uri.sub("\#pui", '')
    @criteria = {}
    @criteria['resolve[]'] = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id', 'linked_instance_uris:id', 'digital_object_uris:id']

    begin
      @result = archivesspace.get_record(url, @criteria)

      if params[:obj_type] == 'digital_objects'
        tree_root = archivesspace.get_raw_record(uri + '/tree/root') rescue nil
        @has_children = tree_root && tree_root['child_count'] > 0
      end

      @repo_info =  @result.repository_information
      @page_title = @result.display_string
      @context = [
        {:uri => @repo_info['top']['uri'], :crumb => @repo_info['top']['name'], :type => 'repository'}
      ].concat(@result.breadcrumb)
      fill_request_info
      if @result['primary_type'] == 'digital_object' || @result['primary_type'] == 'digital_object_component'
        @dig = process_digital(@result['json'])
      else
        @dig = process_digital_instance(@result['json']['instances'])
        process_extents(@result['json'])
      end

      render
    rescue RecordNotFound
      type = "#{(params[:obj_type] == 'archival_objects' ? 'archival' : 'digital')}_object"
      record_not_found(uri, type)
    end
  end

  private

  # return a single processed archival or digital object
  def object_result(url, criteria)
    begin
      archivesspace.get_record(url, criteria)
    rescue RecordNotFound
      {}
    end
  end

  # get archival info
  def digital_archival_info(dig_json)
    Rails.logger.debug("****\tdigital_archival_info: #{dig_json['linked_instances']}")
    unless dig_json['linked_instances'].empty? || !dig_json['linked_instances'][0].dig('ref')
      uri = dig_json['linked_instances'][0].dig('ref')
      uri << '#pui' unless uri.end_with?('#pui')
      arch = object_result(uri, @criteria)
      unless arch.blank?
        arch['json']['html'].keys.each do |type|
          dig_json['html'][type] = arch['json']['html'][type] if dig_json.dig('html', type).blank?
        end
        # GONE # @tree = fetch_tree(uri.sub('#pui','')) if @tree['path_to_root'].blank?
      end
    end
  end

end
