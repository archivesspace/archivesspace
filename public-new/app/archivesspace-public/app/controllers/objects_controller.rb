class ObjectsController <  ApplicationController
  include TreeApis
  include ResultInfo
  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents
  helper_method :process_digital
  helper_method :process_digital_instance

  skip_before_filter  :verify_authenticity_token
  
  DEFAULT_OBJ_FACET_TYPES = %w(repository primary_type subjects agents)
  DEFAULT_OBJ_SEARCH_OPTS = {
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1,
    'sort' =>  'title_sort asc'
  }
  
  def index
    repo_id = params.fetch(:rid, nil)
     if !params.fetch(:q,nil)
      params[:q] = ['*']
      params[:limit] = 'digital_object,archival_object' unless params.fetch(:limit,nil)
      params[:op] = ['OR']
    end
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts(DEFAULT_OBJ_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""] if repo_id
    @base_search = repo_id ? "/repositories/#{repo_id}/objects?" : '/objects?'

    begin
      set_up_and_run_search( params[:limit].split(","), DEFAULT_OBJ_FACET_TYPES, search_opts,params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
    @context = repo_context(repo_id, 'record')
    @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
    @search[:text_within] = @pager.last_page > 1
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
       @sort_opts.push(all_sorts[type])
    end

    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    render 'search/search_results'
  end

  def search
    @base_search  =  "/objects/search?"
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(%w(digital_object archival_object),DEFAULT_OBJ_FACET_TYPES,DEFAULT_OBJ_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/objects' ) and return
    end
    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('record._plural'), :term => params.fetch(:q)[0]})
    render 'search/search_results'
  end

 
  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      @repo_info =  process_repo_info(@result)
      @page_title = strip_mixed_content(@result['json']['display_string'] || @result['json']['title'])
      @tree = fetch_tree(uri)
      @context = get_path(@tree)
      # TODO: This is a monkey patch for digital objects
      if @context.blank?
        @context = []
        unless @result['_resolved_resource'].blank? || @result['_resolved_resource']['json'].blank?
          @context.unshift({:uri => @result['_resolved_resource']['json']['uri'],
                             :crumb => strip_mixed_content(@result['_resolved_resource']['json']['title'])})
        end
      end
      @context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
      @context.push({:uri => '', :crumb => strip_mixed_content(@result['json']['display_string'] || @result['json']['title']) })
      @cite = ''
      cite = get_note(@result['json'], 'prefercite')
      unless cite.blank?
        @cite = strip_mixed_content(cite['note_text'])
      else
        @cite = strip_mixed_content(@result['json']['title']) + "."
        unless @result['_resolved_resource'].blank? || @result['_resolved_resource']['json'].blank?
          @cite += " #{strip_mixed_content(@result['_resolved_resource']['json']['title'])}."
        end
         unless @repo_info['top']['name'].blank?
           @cite += " #{ @repo_info['top']['name']}."
        end
      end
      @cite += "   #{request.original_url}  #{I18n.t('accessed')} " +  Time.now.strftime("%B %d, %Y") + "."
      @agents = process_agents(@result['json']['linked_agents'])
      @subjects = process_subjects(@result['json']['subjects'])
      @dig = process_digital(@result['json'])
      @dig = process_digital_instance(@result['json']['instances']) if @dig.blank?
     else
      @page_title = I18n.t 'errors.error_404'
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
