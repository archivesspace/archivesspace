class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/batch_delete')
  .description("Carry out delete requests against a list of records")
  .params(["record_uris", [String], "A list of record uris"])
  .permissions([])
  .returns([200, :deleted]) \
  do
    results = []
    errors = []

    params[:record_uris].each do |uri|
      response = ::URIResolver.forward_rack_request("DELETE", uri, env)

      if response[0] === 200
        results << ASUtils.json_parse(response[2].first).merge({"uri" => uri})
      else
        errors << {"response" => response[2], "uri" => uri}
      end
    end

    if errors.empty?
      json_response(:status => "OK", :results => results)
    else
      raise BatchDeleteFailed.new(errors)
    end
  end

end
