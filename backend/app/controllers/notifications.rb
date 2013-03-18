class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/notifications')
    .description("Get a stream of notifications")
    .permissions([])
    .params(["last_sequence", Integer, "The last sequence number seen",
             :optional => true,
             :default => 0],)
    .returns([200, "a list of notifications"]) \
  do
    json_response(Notifications.blocking_since(params[:last_sequence]))
  end

end
