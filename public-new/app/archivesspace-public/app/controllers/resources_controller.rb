class ResourcesController <  ApplicationController

  include TreeApis

  skip_before_filter  :verify_authenticity_token


  DEFAULT_RES_FACET_TYPES = %w{primary_type subjects agents}

  DEFAULT_RES_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id',  'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_RES_TYPES = %w{archival_object digital_object agent subject}
  # present a list of resources.  If no repository named, just get all of them.
  def index
    @repo_name = params[:repo] || ""
    query = 'publish:true'
    @base_search = '/repositories'
    if !params.fetch(:rid,'').blank?
      @repo_id = "/repositories/#{params[:rid]}"
      query = "repository:\"#{@repo_id}\" AND #{query}"
      @base_search += "/#{params.fetch(:rid)}"
    end
    @base_search += '/resources?'

    set_up_search(['resource'], [],DEFAULT_RES_SEARCH_OPTS, params, query)
    page = Integer(params.fetch(:page, "1"))
    @results =  archivesspace.search(@query, page, @criteria) || {}
    
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
      redirect_back(fallback_location: "/")
    else
      process_search_results(@base_search)
      render
    end
  end

  def search 
    repo_id = params.require(:repo_id)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    params[:res_id] = res_id
    q = params.fetch(:q,'')
    @base_search = "#{res_id}/search?"
    set_up_search(DEFAULT_RES_TYPES, DEFAULT_RES_FACET_TYPES, DEFAULT_RES_SEARCH_OPTS, params,q)

    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.search(@query,page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}" 
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
# Pry::ColorPrinter.pp @results['results'][0]['_resolved_resource']['json']
      render
    end
  end
  def show
    uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
    record_list = [uri]
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records(record_list,1, @criteria) || {}
    @results = handle_results(@results)  # this should process all notes
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
#Rails.logger.debug(@result['json'].keys)
      #Rails.logger.debug("REPOSITORY:")
#      Pry::ColorPrinter.pp(@result)
      repo = @result['_resolved_repository']['json']
      @page_title = "#{I18n.t('resource._singular')}: #{strip_mixed_content(@result['json']['title'])}"
      @context = [{:uri => repo['uri'], :crumb => repo['name']}, {:uri => nil, :crumb => process_mixed_content(@result['json']['title'])}]
      @tree = fetch_tree(uri)
    else
      @page_title = "#{I18n.t('resource._singular')} {I18n.t('errors.error_404')} NOT FOUND"
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
