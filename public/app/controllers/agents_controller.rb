class AgentsController <  ApplicationController
  include ResultInfo

  skip_before_action  :verify_authenticity_token

  DEFAULT_AG_TYPES = %w{repository resource accession archival_object digital_object}
  DEFAULT_AG_FACET_TYPES = %w{primary_type subjects}
  DEFAULT_AG_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id'],
    'facet.mincount' => 1
  }

  DEFAULT_AG_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'agent',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    repo_id = params.fetch(:rid, nil)
    Rails.logger.debug("repo_id: #{repo_id}")
    if !params.fetch(:q, nil)
      DEFAULT_AG_SEARCH_PARAMS.each do |k, v|
        params[k] = v unless params.fetch(k,nil)
      end
    end
    search_opts = default_search_opts(DEFAULT_AG_SEARCH_OPTS)
    search_opts['fq'] = ["used_within_published_repository:\"/repositories/#{repo_id}\""] if repo_id
    @base_search  =  repo_id ? "/repositories/#{repo_id}/agents?" : '/agents?'
    default_facets = DEFAULT_AG_FACET_TYPES.dup
    default_facets.push('used_within_published_repository') unless repo_id
    page = Integer(params.fetch(:page, "1"))
    set_up_and_run_search( DEFAULT_AG_TYPES, default_facets,  search_opts, params)

    @context = repo_context(repo_id, 'agent')
    if @results['total_hits'] > 1
      @search[:dates_within] = false
      @search[:text_within] = true
    end

    @page_title = I18n.t('agent._plural')
    @results_type = @page_title
    all_sorts = Search.get_sort_opts
    @sort_opts = []
    %w(title_sort_asc title_sort_desc).each do |type|
      @sort_opts.push(all_sorts[type])
    end
    if params[:q].size > 1 || params[:q][0] != '*'
      @sort_opts.unshift(all_sorts['relevance'])
    end
    @no_statement = true
    render 'search/search_results'
  end

  def search
    # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=pui_agent
    @base_search = '/agents/search?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES,  DEFAULT_AG_SEARCH_OPTS, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/agents') and return
    end
    @page_title = I18n.t('agent._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('agent._plural'), :term => params.fetch(:q)[0]})
     render 'search/search_results'
  end


  RETAINED_PARAMETERS = ['filter_fields', 'filter_values']

  def show
    uri = "/agents/#{params[:eid]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource','related_agent_uris:id' ]
    begin
      @result = archivesspace.get_record(uri, @criteria)
      @results = fetch_agent_results(@result['title'],uri, params)
      if !@results.blank?

        extra_params = Hash[RETAINED_PARAMETERS.map {|f|
                              if params[f]
                                [f, params[f]]
                              end
                            }].compact.to_query

        @pager =  Pager.new("#{uri}?#{extra_params}", @results['this_page'],@results['last_page'])
      else
        @pager = nil
      end
     @page_title = strip_mixed_content(@result['json']['title']) || "#{I18n.t('an_agent')}: #{uri}"
      Rails.logger.debug("Agent title: #{@page_title}")
      @context = []
    rescue RecordNotFound
      @type = I18n.t('pui_agent._singular')
      @page_title =  I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
  end

  private
  def fetch_agent_results(title, uri, params)
    @results = []
    qry = "published_agent_uris:\"#{uri}\" AND types:pui"
    @base_search = "#{uri}?"
    set_up_search(DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES, DEFAULT_AG_SEARCH_OPTS, params,qry)
  # we do this to compensate for the way @base_search gets munged in the setup
    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))
    @results =  archivesspace.search(qry,page, @criteria)
    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
    @results
  end
end
