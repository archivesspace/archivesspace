class ClassificationsController <  ApplicationController

  include TreeApis

  skip_before_filter  :verify_authenticity_token

  DEFAULT_CL_TYPES = %w{classification}
  DEFAULT_CL_FACET_TYPES = %w{primary_type subjects agents repository resource}
  DEFAULT_CL_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_CL_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'classification',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    if !params.fetch(:q, nil)
      DEFAULT_CL_SEARCH_PARAMS.each do |k,v|
        params[k] = v
      end
    end
    @base_search = '/classifications?'
    page = Integer(params.fetch(:page, "1"))

    begin
      set_up_and_run_search( DEFAULT_CL_TYPES, DEFAULT_CL_FACET_TYPES,  DEFAULT_CL_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
    @page_title = I18n.t('classification._plural')
    @results_type = @page_title
    @page_title = I18n.t('classification._plural')
    @results_type = @page_title
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
    uri = "/repositories/#{params[:rid]}/classifications/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      Pry::ColorPrinter.pp(@result)
      @page_title = strip_mixed_content(@result['json']['title'])
      @tree = fetch_tree(uri)
      @context = get_path(@tree)
      # TODO: This is a monkey patch for digital objects
      if @context.blank?
        @context = []
      end
      @context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
      @context.push({:uri => '', :crumb => process_mixed_content(@result['json']['title']) })
    else
      @page_title = "#{I18n.t('classification._singular')} #{I18n.t('errors.error_404')}"
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
