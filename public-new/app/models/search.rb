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


  def self.tree_view(record_uri)
    response = JSONModel::HTTP::get_json("/search/published_tree", :node_uri => record_uri)

    return nil if not response

    tree_view = ASUtils.json_parse(response["tree_json"])

    if response['whole_tree_json']
      tree_view['whole_tree'] = ASUtils.json_parse(response['whole_tree_json'])
    end

    tree_view
  end

end
