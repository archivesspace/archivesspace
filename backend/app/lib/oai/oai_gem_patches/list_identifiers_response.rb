module OAI::Provider::Response

  class ListIdentifiers < RecordResponse
    # metadataPrefix is required
    required_parameters :metadata_prefix
  end

end
