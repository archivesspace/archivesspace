require 'search_result_data'

class Search

  def self.for_type(repo_id, type, criteria)
    criteria['type[]'] = Array(type)

    Search.all(repo_id, criteria)
  end


  def self.all(repo_id, criteria)
    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/repositories/#{repo_id}/search", criteria)
    search_data[:criteria] = criteria

    SearchResultData.new(search_data)
  end


  def self.global(criteria, type)
    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/search/#{type}", criteria)
    search_data[:criteria] = criteria
    search_data[:type] = type
    SearchResultData.new(search_data)
  end
end
