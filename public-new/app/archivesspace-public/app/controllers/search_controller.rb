class SearchController < ApplicationController
  include HandleFaceting
  include ProcessResults
  include JsonHelper

  DEFAULT_SEARCH_FACET_TYPES = ['repository','primary_type', 'subjects', 'agents']
  DEFAULT_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource repository accession}.map {|t| "types:#{t}"}.join(" OR ")


  def search
    @criteria = DEFAULT_SEARCH_OPTS
    filtering = FacetFilter.new(DEFAULT_SEARCH_FACET_TYPES, params.fetch(:filter,[]))
    @criteria['filter'] = filtering.filters if !filtering.filters.blank?
    @criteria['facet[]'] = filtering.get_facet_types
    record_types = params.fetch(:recordtypes, nil)
    if record_types
      @query = ''
      record_types.each do |type|
        @query = "#{@query} primary_type:#{type}"
      end
    else
      @query = "#{params.require(:q)} AND (#{DEFAULT_TYPES})"
    end
    @page_search = "/search?q=#{@query}" 

    page = Integer(params.fetch(:page, "1"))
    res_id = params.fetch(:res_id, '')
    repo_id = params.fetch(:repo_id, '')
    if !res_id.blank?
      @query = "resource:\"#{res_id}\" AND #{@query}"
      @page_search = "#{@page_search}&res_id=#{res_id.gsub('/','%2f')}"
    elsif !repo_id.blank?
      @query =  "repository:\"#{repo_id}\" AND #{@query}"
      @page_search = "#{@page_search}&repo_id=#{repo_id.gsub('/','%2f')}"
    end
    Rails.logger.debug("page search: #{@page_search}")

    @results = archivesspace.search(@query, page, @criteria)
# this gets refactored later
    @facets = {}
    hits = Integer(@results['total_hits'])
    if !@results['facets'].blank?
      @results['facets']['facet_fields'].keys.each do |type|
        facet_hash = strip_facets( @results['facets']['facet_fields'][type],1, hits)
        @facets[type] = facet_hash unless facet_hash.blank?
      end
    end

    @results = handle_results(@results)
    if filtering.filters.length > 0
      filtering.filters.each do |f|
        @page_search = "#{@page_search}&filter[]=#{f}"
      end
    end
    @filters = filtering.get_filter_hash

    @pager = Pager.new(@page_search,@results['this_page'],@results['last_page']) 
#    Rails.logger.debug(@pager)
#    Rails.logger.debug("\n\n#{@results}\n")
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end

end
