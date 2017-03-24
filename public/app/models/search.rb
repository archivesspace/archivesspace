require 'search_result_data'

class Search

  def self.all(criteria, repositories)
    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/search", criteria)
    search_data[:criteria] = criteria

    SearchResultData.new(search_data, repositories)
  end


  def self.repo(repo_id, criteria, repositories)
    criteria["page"] = 1 if not criteria.has_key?("page")

    search_data = JSONModel::HTTP::get_json("/repositories/#{repo_id}/search", criteria)
    search_data[:criteria] = criteria

    SearchResultData.new(search_data, repositories)
  end


  def self.get_raw_record(uri)
    begin
      json_str = JSONModel::HTTP::get_json("/search/records",
                                           "uri[]" => ASUtils.wrap(uri))
                 .fetch('results')
                 .fetch(0)
                 .fetch('json')

      ASUtils.json_parse(json_str)
    rescue
      raise RecordNotFound.new("Record not found: #{uri}")
    end
  end

end
