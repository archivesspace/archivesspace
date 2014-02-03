class DigitalObjectChildren < DigitalRecordChildren

  def self.uri_and_remaining_options_for(id = nil, opts = {})
    substitute_parameters("/repositories/:repo_id/digital_objects/:digital_object_id/children", opts)
  end

end
