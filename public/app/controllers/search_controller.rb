class SearchController < ApplicationController

  include PrefixHelper

  DEFAULT_SEARCH_FACET_TYPES = ['repository','primary_type', 'subjects', 'published_agents','langcode']
  DEFAULT_SEARCH_OPTS = {
#    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource repository accession classification subject}


  def search
    @repo_id = params.fetch(:rid, nil)
    repo_url = "/repositories/#{@repo_id}"
    @base_search =  @repo_id ? "#{repo_url}/search?" : '/search?'
    fallback_location = @repo_id ? app_prefix(repo_url) : app_prefix('/search?reset=true');
    @new_search = fallback_location

    if params[:reset] == 'true'
      @reset = true
      params[:rid] = nil
      @search = Search.new(params)
      return render 'search/search_results'
    end

      search_opts = default_search_opts(DEFAULT_SEARCH_OPTS)
      search_opts['fq'] = ["repository:\"#{repo_url}\" OR used_within_published_repository::\"#{repo_url}\""] if @repo_id
    begin
      set_up_advanced_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, search_opts, params)
#NOTE the redirect back here on error!
    rescue Exception => error
    Rails.logger.debug(error.message)
      p error
      flash[:error] = I18n.t('search_results.error')
      redirect_back(fallback_location: root_path ) and return
    end
    page = Integer(params.fetch(:page, "1"))
    Rails.logger.debug("base search: #{@base_search}")
    Rails.logger.debug("query: #{@query}")

    @results = archivesspace.advanced_search(@base_search, page, @criteria)
    @counts = archivesspace.get_types_counts(DEFAULT_TYPES)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = I18n.t('search_results.no_results')
      fallback_location = URI(fallback_location)
      fallback_location.query = URI(@base_search).query + "&reset=true"
      redirect_to(fallback_location.to_s)
    else
      process_search_results(@base_search)
      if @results['total_hits'] > 1
        @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
        @search[:text_within] = true
      end
      @sort_opts = []
      all_sorts = Search.get_sort_opts
      all_sorts.keys.each do |type|
        @sort_opts.push(all_sorts[type])
      end
      render 'search/search_results'
    end
  end

end
