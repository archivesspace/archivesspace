module TreeApis
  extend ActiveSupport::Concern
  # fetch the tree to be manipulated by other methods in this controller
  # TODO: try/catch for non 200 responses
  def fetch_tree(node_uri)
    response = JSONModel::HTTP::get_json("/search/published_tree", :node_uri => node_uri)

    Rails.logger.debug(response.inspect)
    return nil unless response and response.has_key?('tree_json')
    tree = ASUtils.json_parse(response['tree_json'])
  end

end
