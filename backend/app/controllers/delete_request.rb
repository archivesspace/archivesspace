class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/batch_delete')
  .description("Carry out delete requests against a list of records")
  .params(["record_uris", [String], "A list of record uris"],
          ["current_repo_id", Integer, "Optionally passes the caller's current repository. Forwarded to each simulated per-record delete request; only consulted by record types that check it (currently just agents).", :optional => true])
  .permissions([])
  .no_data(true)
  .returns([200, :deleted]) \
  do
    results = []
    errors = []

    params[:record_uris].each do |uri|
      response = forward_delete_request(uri, params[:current_repo_id])

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

  private

  # This approach isn't ideal.  We effectively simulate DELETE requests against
  # the backend as if the client had sent them one by one.  Currently we have to
  # do this because we rely on the individual requests for the permission check
  # (since batch delete can delete records of any type, but different records
  # might have different permissions, and those are known only to the Endpoint
  # declarations).
  #
  # In the future, maybe batch delete should be a permission of its own.  Or we
  # need a better way to determine which permission is needed to delete each
  # type of record.
  def forward_delete_request(uri, current_repo_id = nil)
    simulated_env = env.merge('PATH_INFO' => uri, 'REQUEST_METHOD' => "DELETE")

    if current_repo_id
      query_param = "current_repo_id=#{current_repo_id}"
      simulated_env['QUERY_STRING'] = [simulated_env['QUERY_STRING'], query_param].reject {|s| s.nil? || s.empty?}.join('&')
    end

    ArchivesSpaceService.call(simulated_env)
  end

end
