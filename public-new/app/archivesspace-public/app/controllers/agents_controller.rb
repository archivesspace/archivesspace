class AgentsController <  ApplicationController

  include TreeApis

  skip_before_filter  :verify_authenticity_token

  DEFAULT_AG_TYPES = %w{repository resource archival_object digital_object}
  DEFAULT_AG_FACET_TYPES = %w{primary_type subjects}
  DEFAULT_AG_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'facet.mincount' => 1
  }

  def index
#    repo_id = params.fetch(:repo_id, nil)
    if params.fetch(:q, nil)
        pass_params = params
    else
      pass_params = {}
      pass_params[:q] = ['*']
      pass_params[:recordtypes] = %w(agent_person agent_family agent_corporate_entity)
      pass_params[:limit] = pass_params[:recordtypes].join(",")
      pass_params[:op] = ['OR']
      pass_params[:field] = ['title']
    end
    @base_search  =  '/agents?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES,  DEFAULT_AG_SEARCH_OPTS, pass_params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/agents') and return
    end
    @page_title = I18n.t('agent._plural')
    @results_type = @page_title
    render 'search/search_results'
  end

  def search
    # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=agent_person,agent_family,agent_corporate_entity
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
#      Pry::ColorPrinter.pp(@result)
      @results = fetch_agent_results(@result['title'],uri, params)
      if !@results.blank?
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
    qry = "#{params.fetch(:q,'*')} AND  agents:\"#{title}\""
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
