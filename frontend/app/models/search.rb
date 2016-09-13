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
    queries = Array(criteria['filter_term[]']).map do |json_filter|
      filter = ASUtils.json_parse(json_filter)

      {
        'op' => 'AND',
        'type' => 'text',
        'field' => filter.keys[0],
        'value' => filter.values[0],
      }
    end

    return if queries.empty?

    result = AdvancedQueryBuilder.build_query_from_form(queries)

    criteria['filter'] = result.to_json
  end

end
