class SearchController < ApplicationController

  def search
    @query = params.require(:q)
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page)
    @results['results'].each do |result|
#      Rails.logger.debug("\nresult")
#      result.each do |k, v|
#        if k != 'json'
#          Rails.logger.debug("#{k} -> #{v}\n")
#        end
#      end
      if !result['json'].blank?
        result['json'] = JSON.parse(result['json']) || {}
#        Rails.logger.debug("Hashed: \n")
#        result['json'].each do |k, v|
#       Rails.logger.debug("#{k} -> #{v}\n")
#        end
      else
        result['json'] = {}
      end
    end
    @pager = Pager.new("/search?q=#{@query}",@results['this_page'],@results['last_page']) 
#    Rails.logger.debug(@pager)
#    Rails.logger.debug("\n\n#{@results}\n")
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end

end
