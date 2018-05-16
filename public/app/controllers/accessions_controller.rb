class AccessionsController <  ApplicationController
  include ResultInfo

  skip_before_action  :verify_authenticity_token

  DEFAULT_AC_TYPES = %w{accession}
  DEFAULT_AC_FACET_TYPES = %w{primary_type subjects published_agents repository}
  DEFAULT_AC_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_AC_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'accession',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    if !params.fetch(:q, nil)
      DEFAULT_AC_SEARCH_PARAMS.each do |k, v|
        params[k] = v
      end
    end
    @repo_id = params.fetch(:rid, nil)
    if @repo_id
      @base_search =  "/repositories/#{@repo_id}/accessions?"
      repo = archivesspace.get_record("/repositories/#{@repo_id}")
      @repo_name = repo.display_string
    else
      @base_search = '/accessions?'
    end
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts( DEFAULT_AC_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{@repo_id}\""] if @repo_id
    begin
      set_up_and_run_search( DEFAULT_AC_TYPES, DEFAULT_AC_FACET_TYPES,  search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/') and return
    end

    if @results['total_hits'] > 1
      @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
      @search[:text_within] = true
    end
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
       @sort_opts.push(all_sorts[type])
    end

    @page_title = I18n.t('accession._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'

  end

  def search
      # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=accession
    @base_search = '/accessions/search?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_AC_TYPES, DEFAULT_AC_FACET_TYPES,  DEFAULT_AC_SEARCH_OPTS, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/') and return
    end
    @page_title = I18n.t('accession._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('accession._plural'), :term => params.fetch(:q)[0]})
     render 'search/search_results'
  end

  def show
    uri = "/repositories/#{params[:rid]}/accessions/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'related_resource_uris:id', 'top_container_uri_u_sstr:id', 'digital_object_uris:id']
    begin
      @result =  archivesspace.get_record(uri, @criteria)
      @page_title = @result.display_string
      @context = []
      @context.unshift({:uri => @result.resolved_repository['uri'], :crumb =>  @result.resolved_repository['name']})
      @context.push({:uri => '', :crumb => @result.display_string })
      fill_request_info
    rescue RecordNotFound
      @type = I18n.t('accession._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
  end
end
