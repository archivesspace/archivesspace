class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/update-feed')
    .description("Get a stream of updated records")
    .preconditions(proc { current_user.can?(:index_system) })
    .params(["last_sequence", Integer, "The last sequence number seen",
             :optional => true,
             :default => 0])
    .returns([200, "a list of records and sequence numbers"]) \
  do
    updates = RealtimeIndexing.blocking_updates_since(params[:last_sequence])

    json_response(updates)
  end

end
