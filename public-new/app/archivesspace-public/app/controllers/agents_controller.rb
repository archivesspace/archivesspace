class AgentsController <  ApplicationController
  include ProcessResults
  include TreeApis
  include JsonHelper

  skip_before_filter  :verify_authenticity_token

  DEFAULT_AG_TYPES = %w{repository resource archival_object digital_object}
  DEFAULT_AG_FACET_TYPES = %w{primary_type subjects}
  DEFAULT_AG_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'facet.mincount' => 1
  }



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
    set_up_search(DEFAULT_AG_TYPES, DEFAULT_AG_FACET_TYPES, DEFAULT_AG_SEARCH_OPTS, params)
    q = params.fetch(:q,'*')
    page = Integer(params.fetch(:page, "1"))
    qry = "#{q} AND agents:\"#{title}\""
    @results =  archivesspace.search(qry,page, @criteria)
    if @results['total_hits'] > 0
      process_search_results("#{uri}?q=#{q}")
    else
      @results = []
    end
    @results
  end
end
