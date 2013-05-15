class ResourceChildren < JSONModel(:archival_object_children)

  def self.uri_and_remaining_options_for(id = nil, opts = {})
    uri = URI("/repositories/:repo_id/resource/#{id}/children")
    self.substitute_parameters(uri, opts)
  end

end
