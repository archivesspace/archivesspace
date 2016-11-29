class AgentsController <  ApplicationController

  include TreeApis

  skip_before_filter  :verify_authenticity_token

  DEFAULT_AG_TYPES = %w{repository resource archival_object digital_object}
  DEFAULT_AG_FACET_TYPES = %w{primary_type subjects used_within_repository}
  DEFAULT_AG_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'facet.mincount' => 1
  }

  DEFAULT_AG_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'pui_agent',
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
    search_opts['fq'] = ["used_within_repository:\"/repositories/#{repo_id}\""] if repo_id
    @base_search  =  repo_id ? "/repositories/#{repo_id}/agents?" : '/agents?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES,  search_opts, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end

    @context = repo_context(repo_id, 'agent')
    @search[:dates_within] = false
    @search[:text_within] = @pager.last_page > 1

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
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/agents') and return
    end
    @page_title = I18n.t('agent._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('agent._plural'), :term => params.fetch(:q)[0]})
     render 'search/search_results'
  end


  def show
    uri = "/agents/#{params[:eid]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    results =  archivesspace.search_records([uri],1,@criteria)
    results =  handle_results(results)
    if !results['results'].blank? && results['results'].length > 0
      @result = results['results'][0]
      Pry::ColorPrinter.pp(@result)
      @results = fetch_agent_results(@result['title'],uri, params)
      if !@results.blank?
        params[:q] = '*'
#Pry::ColorPrinter.pp(@results['results'])
        @pager =  Pager.new("#{uri}?q=#{params.fetch(:q,'*')}", @results['this_page'],@results['last_page'])
      else
        @pager = nil
      end
     @page_title = strip_mixed_content(@result['json']['title']) || "#{I18n.t('an_agent')}: #{uri}"
      Rails.logger.debug("Agent title: #{@page_title}")
      @context = []
    else
      @page_title =  "#{I18n.t('an_agent')} #{I18n.t('errors.error_404')}"
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end

  private
  def fetch_agent_results(title, uri, params)
    @results = []
    qry = "agents:\"#{title}\""
    @base_search = "#{uri}?"
    set_up_search(DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES, DEFAULT_AG_SEARCH_OPTS, params,qry)
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
