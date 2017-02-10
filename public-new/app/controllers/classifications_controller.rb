class ClassificationsController <  ApplicationController

  include ResultInfo
  include TreeApis

  skip_before_filter  :verify_authenticity_token

  DEFAULT_CL_TYPES = %w{pui_record_group}
  DEFAULT_CL_FACET_TYPES = %w{primary_type subjects agents repository resource}
  DEFAULT_CL_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
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
      DEFAULT_CL_SEARCH_PARAMS.each do |k,v|
        params[k] = v
      end
    end
    search_opts = default_search_opts( DEFAULT_CL_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""] if repo_id

    @base_search = repo_id ? "repositories/#{repo_id}/classifications?" : '/classifications?'
    page = Integer(params.fetch(:page, "1"))

    begin
      set_up_and_run_search( DEFAULT_CL_TYPES, DEFAULT_CL_FACET_TYPES,  search_opts, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
    unless @pager.one_page?
      @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
      @search[:text_within] = true
    end
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
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
      set_up_and_run_search( DEFAULT_CL_TYPES, DEFAULT_CL_FACET_TYPES,  DEFAULT_CL_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
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
      fetch_and_process(uri)
      fetch_linked_records(uri)
    rescue RecordNotFound
      @type =  I18n.t('classification._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end

  def term
    begin
      uri = "/repositories/#{params[:rid]}/classification_terms/#{params[:id]}"
      fetch_and_process(uri)
      fetch_linked_records(uri)
      render 'classifications/show'
    rescue RecordNotFound
      @type =  I18n.t('classification_term._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
     @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end

  # we use this to get and process both classifications and classification terms
  def fetch_and_process(uri)
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'agent_uris:id']
    @result = archivesspace.get_record(uri, @criteria)

    @tree = fetch_tree(uri)
    @context = get_path(@tree)
    # TODO: This is a monkey patch for digital objects
    if @context.blank?
      @context = []
    end
    @context.unshift({:uri => @result.resolved_repository['uri'], :crumb =>  @result.resolved_repository['name']})
    @context.push({:uri => '', :crumb => @result.display_string })
  end

  def fetch_linked_records(uri)
    qry = "classification_uris:\"#{uri}\""
    @base_search = "#{uri}?"
    search_opts = default_search_opts(DEFAULT_CL_SEARCH_OPTS)
    search_opts['fq']=[qry]

    set_up_search(['pui'], DEFAULT_CL_FACET_TYPES, search_opts, params, qry)

    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))

    @results =  archivesspace.search(@query, page, @criteria)

    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
  end

end
