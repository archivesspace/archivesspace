class SubjectsController <  ApplicationController

  skip_before_filter  :verify_authenticity_token
  DEFAULT_SUBJ_TYPES = ['subject']
  DEFAULT_SUBJ_FACET_TYPES = %w{primary_type  used_within_repository}
  DEFAULT_SUBJ_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'facet.mincount' => 1
   }
  DEFAULT_SUBJ_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'subject',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    repo_id = params.fetch(:rid, nil)
    if !params.fetch(:q, nil) 
      DEFAULT_SUBJ_SEARCH_PARAMS.each do |k, v|
        params[k] = v unless params.fetch(k,nil)
      end
    end
    search_opts = DEFAULT_SUBJ_SEARCH_OPTS
    search_opts['fq'] = ["used_within_repository:\"/repositories/#{repo_id}\""] if repo_id
    @base_search  =  repo_id ? "/repositories/#{repo_id}/subjects?" : '/subjects?' 
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(['subject'],DEFAULT_SUBJ_FACET_TYPES,search_opts, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/' ) and return
    end
    @page_title = I18n.t('subject._plural')
    @results_type = @page_title
    all_sorts = Search.get_sort_opts
    @sort_opts = []
    %w(title_sort_asc title_sort_desc).each do |type|
      @sort_opts.push(all_sorts[type])
    end

    render 'search/search_results'
  end

  def search
  # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=subject
     @base_search  =  "/subjects/search?"
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(['subject'],DEFAULT_SUBJ_FACET_TYPES,DEFAULT_SUBJ_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/subjects' ) and return
    end
    @page_title = I18n.t('subject._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('subject._plural'), :term => params.fetch(:q)[0]})
    @sort_opts = []
    %w(relevance title_sort_asc title_sort_desc).each do |type|
      @sort_opts.push(all_sorts[type])
    end

    render 'search/search_results'
  end

  def show
    sid = params.require(:id)
    uri = "/subjects/#{sid}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    results =  archivesspace.search_records([uri],1,@criteria)
    results =  handle_results(results)
    if !results['results'].blank? && results['results'].length > 0
      @result = results['results'][0]
      Pry::ColorPrinter.pp(@result)
      @results = fetch_subject_results(@result['title'],uri, params)
      if !@results.blank?
        @pager =  Pager.new(@base_search, @results['this_page'],@results['last_page']) 
      else
        @pager = nil
      end
      @page_title = strip_mixed_content(@result['json']['title']) || "#{I18n.t('subject._singular')} #{uri}"
#      Rails.logger.debug("subject title: #{@page_title}")
      @context = []
    else
      @page_title = I18n.t 'errors.error_404'
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
  private 
  
  def fetch_subject_results(title, uri, params)
    @results = []
    qry = "#{params.fetch(:q,'*')} AND subjects:\"#{title}\""
    @base_search = "#{uri}?"
    set_up_search(DEFAULT_SUBJ_TYPES, DEFAULT_SUBJ_FACET_TYPES, DEFAULT_SUBJ_SEARCH_OPTS, params, qry)
    page = Integer(params.fetch(:page, "1"))
    Rails.logger.debug("subject results query: #{@query}")
    @results =  archivesspace.search(@query,page, @criteria)
    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
    @results
  end

end
