class ResourceChildren < ArchivalRecordChildren

  def self.uri_and_remaining_options_for(id = nil, opts = {})
    substitute_parameters("/repositories/:repo_id/resources/:resource_id/children", opts)
  end

end
