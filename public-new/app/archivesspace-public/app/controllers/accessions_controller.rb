class AccessionsController <  ApplicationController
  include ProcessResults
  include TreeApis
  include JsonHelper

  skip_before_filter  :verify_authenticity_token

  def show
    uri = "/repositories/#{params[:rid]}/accessions/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      Pry::ColorPrinter.pp(@result)
      @page_title = "#{@result['json']['title']}"
      @context = []
      @context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
      @context.push({:uri => '', :crumb => @result['json']['title'] })
    else
      @page_title = "NOT FOUND"
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
