class SearchController < ApplicationController
  include ProcessResults
 
  def search
    @criteria = {}
    @criteria['sort'] = 'title asc'
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
  
   @query = params.require(:q)
    @query = "#{@query} AND publish:true"
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page, @criteria)
    @results = handle_results(@results)
    @pager = Pager.new("/search?q=#{@query}",@results['this_page'],@results['last_page']) 
#    Rails.logger.debug(@pager)
#    Rails.logger.debug("\n\n#{@results}\n")
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end

end
