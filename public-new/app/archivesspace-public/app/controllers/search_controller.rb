class SearchController < ApplicationController

  DEFAULT_SEARCH_FACET_TYPES = ['repository','primary_type', 'subjects', 'agents']
  DEFAULT_SEARCH_OPTS = {
#    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource repository accession classification subject}


  def search
    @base_search = "/search?"
    begin
      set_up_advanced_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, DEFAULT_SEARCH_OPTS, params)
#NOTE the redirect back here on error!
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '\\' ) and return
    end
    page = Integer(params.fetch(:page, "1"))
    Rails.logger.debug("base search: #{@base_search}")
    Rails.logger.debug("query: #{@query}")
   
    @results = archivesspace.advanced_search(@base_search, page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
      @search_terms = search_terms(params)
      Rails.logger.debug("Search terms: #{@search_terms}")
      render
    end
  end

end
