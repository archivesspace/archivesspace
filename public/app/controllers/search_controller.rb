class SearchController < ApplicationController

  include PrefixHelper

  before_action :validate_params

  DEFAULT_SEARCH_FACET_TYPES = ['repository', 'primary_type', 'subjects', 'published_agents', 'langcode']
  DEFAULT_SEARCH_OPTS = {
#    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'linked_instance_uris:id'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES = %w{archival_object digital_object digital_object_component agent resource repository accession classification subject}
  YEAR_FIELD_REGEX = /^\d{1,4}$/

  class InvalidSearchParams < StandardError
  end

  rescue_from InvalidSearchParams, :with => :render_invalid_params

  def search
    @repo_id = params.fetch(:rid, nil)
    repo_url = "/repositories/#{@repo_id}"
    @base_search = @repo_id ? "#{repo_url}/search?" : '/search?'
    fallback_location = @repo_id ? app_prefix(repo_url) : app_prefix('/search?reset=true');
    @new_search = fallback_location

    if params[:reset] == 'true' || !params.has_key?(:q)
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

    if @results['total_hits'].blank? || @results['total_hits'] == 0
      flash[:notice] = I18n.t('search_results.no_results')
      fallback_location = URI(fallback_location)
      fallback_location.query = URI(@base_search).query + "&reset=true"
      redirect_to(fallback_location.to_s)
    else
      process_search_results(@base_search)
      if @results['total_hits'] > 1
        @search[:dates_within] = true if params.fetch(:filter_from_year, '').blank? && params.fetch(:filter_to_year, '').blank?
        @search[:text_within] = true
      end
      @sort_opts = []
      all_sorts = Search.get_sort_opts
      all_sorts.keys.each do |type|
        @sort_opts.push(all_sorts[type])
      end
      # If there are any repositories in the results, get counts of their collections
      @counts = {}
      @results.records.each do |result|
        if result['primary_type'] == 'repository'
          @counts[result.uri] = get_collection_counts(result.uri)
        end
      end
      render 'search/search_results'
    end
  end

  private

  # get counts of collections belonging to a repository
  def get_collection_counts(repo_uri)
    types = ['pui_collection']
    counts = archivesspace.get_types_counts(types, repo_uri)
    final_counts = {}
    counts.each do |k, v|
      final_counts[k.sub("pui_", '')] = v
    end
    final_counts['resource'] = final_counts['collection']
    final_counts
  end

  def validate_params
    ["from_year", "to_year"].each do |field|
      next unless params[field]
      params[field].each do |field_item|
        next if field_item.nil? || field_item.empty?
        next if field_item.match? YEAR_FIELD_REGEX
        field_item = CGI::escapeHTML(URI.decode_www_form_component(field_item))
        raise InvalidSearchParams.new(I18n.t('errors.invalid_search_params', value: field_item, field: I18n.t('search_results.filter.' + field)))
      end
    end
  end

  def render_invalid_params(error)
    flash[:error] = error.message
    redirect_to('/')
  end

end
