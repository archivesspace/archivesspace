class ObjectsController <  ApplicationController
  include ProcessResults
  include TreeApis
  skip_before_filter  :verify_authenticity_token

  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      Pry::ColorPrinter.pp(@result['json'])
      @page_title = "#{@result['json']['title']}"
      @tree = fetch_tree(uri)
      @context = get_path(@tree)
      @context.push({:uri => '', :crumb => @result['json']['title'] })
    else
      @page_title = "NOT FOUND"
    end
  end
end
