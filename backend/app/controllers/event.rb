class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/events')
    .description("Create an Event")
    .params(["event", JSONModel(:event), "The Event to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Event, :event)
  end


  Endpoint.get('/repositories/:repo_id/events/:event_id')
    .description("Get an Event by ID")
    .params(["event_id", Integer, "The Event ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true]
            )
    .returns([200, "(:event)"],
             [404, '{"error":"Event not found"}']) \
  do
    json = Event.to_jsonmodel(params[:event_id], :event, params[:repo_id])

    json_response(resolve_references(json.to_hash, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/events/linkable-records/list')
    .description("Get a list of records matching some search criteria that can be linked to an event")
    .params(["q", /[\w0-9 -.]/, "The record title prefix to match"])
    .returns([200, "A list of matching records"]) \
  do
    json_response(Event.linkable_records_for(params[:q]))
  end


end
