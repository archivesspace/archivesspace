class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/events')
    .description("Create an Event")
    .params(["event", JSONModel(:event), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_event_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Event, params[:event])
  end


  Endpoint.post('/repositories/:repo_id/events/:id')
    .description("Update an Event")
    .params(["id", :id],
            ["event", JSONModel(:event), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_event_record])
    .returns([200, :updated]) \
  do
    handle_update(Event, params[:id], params[:event])
  end


  Endpoint.get('/repositories/:repo_id/events')
    .description("Get a list of Events for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:event)]"]) \
  do
    handle_listing(Event, params)
  end


  Endpoint.get('/repositories/:repo_id/events/:id')
    .description("Get an Event by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve]
            )
    .permissions([:view_repository])
    .returns([200, "(:event)"],
             [404, "Not found"]) \
  do
    json = Event.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.post('/repositories/:repo_id/events/:id/suppressed')
    .description("Suppress this record from non-managers")
    .params(["id", :id],
            ["suppressed", BooleanParam, "Suppression state"],
            ["repo_id", :repo_id])
    .permissions([:suppress_archival_record])
    .returns([200, :suppressed]) \
  do
    sup_state = Event.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.delete('/repositories/:repo_id/events/:id')
    .description("Delete an event record")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_event_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Event, params[:id])
  end


end
