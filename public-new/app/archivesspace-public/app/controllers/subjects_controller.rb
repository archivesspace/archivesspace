class SubjectsController <  ApplicationController
  include ProcessResults
  include JsonHelper

  skip_before_filter  :verify_authenticity_token

  def show
    uri = "/subjects/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
#      Pry::ColorPrinter.pp(@result)
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
end
