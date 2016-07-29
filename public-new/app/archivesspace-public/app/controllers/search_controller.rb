class SearchController < ApplicationController

  def search
    @query = params.require(:q)
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page)
    @pager = Pager.new("/search?q=#{@query}",@results['this_page'],@results['last_page']) 
#    Rails.logger.debug(@pager)
#    Rails.logger.debug("\n\n#{@results}\n")
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end

end
