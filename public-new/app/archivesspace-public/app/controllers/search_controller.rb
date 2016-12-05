class SearchController < ApplicationController

  DEFAULT_SEARCH_FACET_TYPES = ['repository','primary_type', 'subjects', 'agents']
  DEFAULT_SEARCH_OPTS = {
#    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource repository accession classification subject}


  def search
    @repo_id = params.fetch(:rid, nil)
    repo_url = "/repositories/#{@repo_id}"
    @base_search =  @repo_id ? "#{repo_url}/search?" : '/search?'

    search_opts = default_search_opts(DEFAULT_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"#{repo_url}\" OR used_within_repository::\"#{repo_url}\""] if @repo_id
    begin
      set_up_advanced_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, search_opts, params)
#NOTE the redirect back here on error!
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/' ) and return
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
      @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
      @search[:text_within] = @pager.last_page > 1
      @sort_opts = []
      all_sorts = Search.get_sort_opts
      all_sorts.keys.each do |type|
        @sort_opts.push(all_sorts[type])
      end
#      @search_terms = search_terms(params)
#      Rails.logger.debug("Search terms: #{@search_terms}")
      render 'search/search_results'
    end
  end

end
