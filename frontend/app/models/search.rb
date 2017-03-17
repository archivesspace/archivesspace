require 'search_result_data'
require 'advanced_query_builder'

class Search

  def self.for_type(repo_id, type, criteria)
    criteria['type[]'] = Array(type)

    Search.all(repo_id, criteria)
  end


  def self.all(repo_id, criteria)
    build_filters(criteria)

    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/repositories/#{repo_id}/search", criteria)
    search_data[:criteria] = criteria

    SearchResultData.new(search_data)
  end


  def self.global(criteria, type)
    build_filters(criteria)

    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/search/#{type}", criteria)
    search_data[:criteria] = criteria
    search_data[:type] = type
    SearchResultData.new(search_data)
  end

  private

  def self.build_filters(criteria)
    queries = AdvancedQueryBuilder.new

    Array(criteria['filter_term[]']).each do |json_filter|
      filter = ASUtils.json_parse(json_filter)
      queries.and(filter.keys[0], filter.values[0])
    end

    unless queries.empty?
      criteria['filter'] = queries.build.to_json
    end
  end

end
