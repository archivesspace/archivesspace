class ResourcesController <  ApplicationController
  include HandleFaceting
  include ProcessResults
  include TreeApis
  include JsonHelper
  skip_before_filter  :verify_authenticity_token


  DEFAULT_RES_FACET_TYPES = %w{primary_type subjects agents}

  DEFAULT_RES_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id',  'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES = %w{archival_object digital_object agent subject}
  # present a list of resources.  If no repository named, just get all of them.
  def index
    @repo_name = params[:repo] || ""
    set_up_search(['resource'], [],DEFAULT_RES_SEARCH_OPTS, params)
    query = 'publish:true'
    base_search = '/repositories'
    if !params.fetch(:rid,'').blank?
      @repo_id = "/repositories/#{params[:rid]}"
      query = "repository:\"#{@repo_id}\" AND #{query}"
      base_search += "/#{params.fetch(:rid)}"
    end
    base_search += '/resources'
    @criteria = DEFAULT_RES_SEARCH_OPTS
    page = Integer(params.fetch(:page, "1"))
    page_size =  params.fetch('page_size',  AppConfig[:search_results_page_size].to_s).to_i 
    @criteria['page_size'] = page_size
    @results =  archivesspace.search(query, page, @criteria) || {}
    process_search_results("#{base_search}?q=#{query}")
    render
  end

  def search 
    set_up_search(DEFAULT_TYPES, DEFAULT_RES_FACET_TYPES, DEFAULT_RES_SEARCH_OPTS, params)
     repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    q = params.require(:q)
    page = Integer(params.fetch(:page, "1"))
    qry = "#{q} AND resource:\"#{res_id}\""
    @results = archivesspace.search(qry,page, @criteria)
    process_search_results("#{res_id}/search?q=#{q}")
    render
  end
  def show
    uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
    record_list = [uri]
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id']
    @results =  archivesspace.search_records(record_list,1, @criteria) || {}
    @results = handle_results(@results)  # this should process all notes
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
#Rails.logger.debug(@result['json'].keys)
      #Rails.logger.debug("REPOSITORY:")
#      Pry::ColorPrinter.pp(@result['_resolved_repository']['json'])
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
