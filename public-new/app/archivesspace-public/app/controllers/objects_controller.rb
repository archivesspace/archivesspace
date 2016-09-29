class ObjectsController <  ApplicationController
  include TreeApis


  skip_before_filter  :verify_authenticity_token

  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id']
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
      @context.push({:uri => '', :crumb => @result['json']['title'] })
    else
      @page_title = I18n.t 'errors.error_404'
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
