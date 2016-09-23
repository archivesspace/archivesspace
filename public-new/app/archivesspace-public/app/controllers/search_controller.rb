class SearchController < ApplicationController

  DEFAULT_SEARCH_FACET_TYPES = ['repository','primary_type', 'subjects', 'agents']
  DEFAULT_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource repository accession classification subject}


  def search
    set_up_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, DEFAULT_SEARCH_OPTS, params)
    record_types = params.fetch(:recordtypes, nil)
    if record_types
      @query = ''
      record_types.each do |type|
        @query = "primary_type:#{type} #{@query}"
      end
      @query = "publish:true AND (#{@query})"
    else
      @query = params.require(:q)
    end
    base_search = "/search?q=#{@query}"
    page = Integer(params.fetch(:page, "1"))
    res_id = params.fetch(:res_id, '')
    repo_id = params.fetch(:repo_id, '')
    if !res_id.blank?
      @query = "resource:\"#{res_id}\" AND #{@query}"
      base_search = "#{base_search}&res_id=#{res_id.gsub('/','%2f')}"
    elsif !repo_id.blank?
      @query =  "repository:\"#{repo_id}\" AND #{@query}"
      base_search = "#{base_search}&repo_id=#{repo_id.gsub('/','%2f')}"
    end
    Rails.logger.debug("base search: #{base_search}")

    @results = archivesspace.search(@query, page, @criteria)
    process_search_results(base_search)
    render
  end

end
