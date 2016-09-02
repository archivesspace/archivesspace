class SearchController < ApplicationController
  include ProcessResults
  include JsonHelper

  def search
    @criteria = {}
    @criteria['sort'] = 'title asc'
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    record_type = params.fetch(:recordtype, nil)
    if record_type
      @query = "primary_type:#{record_type}"
    else
      @query = params.require(:q)
    end
    page_search = "/search?q=#{@query}" 

    @query = "#{@query} AND publish:true"
    page = Integer(params.fetch(:page, "1"))
    res_id = params.fetch(:res_id, '')
    repo_id = params.fetch(:repo_id, '')
    if !res_id.blank?
      @query = "resource:\"#{res_id}\" AND #{@query}"
      page_search = "#{page_search}&res_id=#{res_id.gsub('/','%2f')}"
    elsif !repo_id.blank?
      @query =  "repository:\"#{repo_id}\" AND #{@query}"
      page_search = "#{page_search}&repo_id=#{repo_id.gsub('/','%2f')}"
    end
    Rails.logger.debug("page search: #{page_search}")

    @results = archivesspace.search(@query, page, @criteria)
    @results = handle_results(@results)
    @pager = Pager.new(page_search,@results['this_page'],@results['last_page']) 
#    Rails.logger.debug(@pager)
#    Rails.logger.debug("\n\n#{@results}\n")
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end

end
