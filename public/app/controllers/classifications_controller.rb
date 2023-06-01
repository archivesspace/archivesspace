class ClassificationsController < ApplicationController

  include ResultInfo

  skip_before_action  :verify_authenticity_token

  before_action(:only => [:show, :term]) {
    process_slug_or_id(params)
  }

  DEFAULT_CL_TYPES = %w{pui_record_group}
  DEFAULT_CL_FACET_TYPES = %w{primary_type subjects published_agents repository resource}
  DEFAULT_CL_SEARCH_OPTS = {
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_CL_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'pui_record_group',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    repo_id = params.fetch(:rid, nil)
    if !params.fetch(:q, nil)
      DEFAULT_CL_SEARCH_PARAMS.each do |k, v|
        params[k] = v
      end
    end
    search_opts = default_search_opts( DEFAULT_CL_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""] if repo_id

    @base_search = repo_id ? "repositories/#{repo_id}/classifications?" : '/classifications?'
    page = Integer(params.fetch(:page, "1"))

    begin
      set_up_and_run_search( DEFAULT_CL_TYPES, DEFAULT_CL_FACET_TYPES, search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/') and return
    end

    @context = repo_context(repo_id, 'classification')
    if @results['total_hits'] > 1
      @search[:dates_within] = true if params.fetch(:filter_from_year, '').blank? && params.fetch(:filter_to_year, '').blank?
      @search[:text_within] = true
    end
    @sort_opts = []

    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
      next if type == 'year_sort'
      @sort_opts.push(all_sorts[type])
    end
    @page_title = I18n.t('classification._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'
  end

  def search
      # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=classification
    @base_search = '/classifications/search?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_CL_TYPES, DEFAULT_CL_FACET_TYPES, DEFAULT_CL_SEARCH_OPTS, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/') and return
    end
    @page_title = I18n.t('classification._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('classification._plural'), :term => params.fetch(:q)[0]})
    render 'search/search_results'
  end


  def show
    begin
      uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
      tree_root = archivesspace.get_raw_record(uri + '/tree/root') rescue nil
      @has_children = tree_root && tree_root['child_count'] > 0

      fetch_and_process(uri)
      fetch_linked_records(uri)
    rescue RecordNotFound
      record_not_found(uri, 'classification')
    end
  end

  def term
    begin
      uri = "/repositories/#{params[:rid]}/classification_terms/#{params[:id]}"
      fetch_and_process(uri)
      fetch_linked_records(uri)

      # Always show the sidebar for these
      @has_children = true

      render 'classifications/show'
    rescue RecordNotFound
      record_not_found(uri, 'classification_term')
    end
  end

  # we use this to get and process both classifications and classification terms
  def fetch_and_process(uri)
    @criteria = {}
    @criteria['resolve[]'] = ['repository:id', 'resource:id@compact_resource', 'agent_uris:id']
    @result = archivesspace.get_record(uri, @criteria)
    @context = @result.breadcrumb
  end

  def fetch_linked_records(uri)
    qry = "classification_uris:\"#{uri}\""
    @base_search = "#{uri}?"
    search_opts = default_search_opts(DEFAULT_CL_SEARCH_OPTS)
    search_opts['fq']=[qry]

    set_up_search(['pui'], DEFAULT_CL_FACET_TYPES, search_opts, params, qry)

    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page, @criteria)

    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
  end

  def tree_root
    @root_uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
    render json: archivesspace.get_raw_record(@root_uri + '/tree/root')
  rescue RecordNotFound
    render json: {}, status: 404
  end

  def tree_node
    @root_uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
    render json:
       archivesspace.get_raw_record(@root_uri + '/tree/node_' + params[:node])
  rescue RecordNotFound
    render json: {}, status: 404
  end

  def tree_waypoint
    @root_uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
    url = @root_uri + '/tree/waypoint_' + params[:node] + '_' + params[:offset]
    render json: archivesspace.get_raw_record(url)
  rescue RecordNotFound
    render json: {}, status: 404
  end

  def tree_node_from_root
    @root_uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
    url = @root_uri + '/tree/node_from_root_' + params[:node_ids].first
    render json: archivesspace.get_raw_record(url)
  rescue RecordNotFound
    render json: {}, status: 404
  end
end
