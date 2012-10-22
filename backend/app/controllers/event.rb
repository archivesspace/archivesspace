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




  # Endpoint.post('/repositories/:repo_id/archival_objects/:archival_object_id')
  #   .description("Update an Archival Object")
  #   .params(["archival_object_id", Integer, "The Archival Object ID to update"],
  #           ["archival_object", JSONModel(:archival_object), "The Archival Object data to update", :body => true],
  #           ["repo_id", :repo_id])
  #   .returns([200, :updated],
  #            [400, :error],
  #            [409, '{"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}']) \
  # do
  #   handle_update(ArchivalObject, :archival_object_id, :archival_object)
  # end


  # Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id/children')
  #   .description("Get the children of an Archival Object")
  #   .params(["archival_object_id", Integer, "The Archival Object ID"],
  #           ["repo_id", :repo_id])
  #   .returns([200, "[(:archival_object)]"],
  #            [404, '{"error":"ArchivalObject not found"}']) \
  # do
  #   ao = ArchivalObject.get_or_die(params[:archival_object_id], params[:repo_id])
  #   json_response(ao.children.map {|child|
  #                   ArchivalObject.to_jsonmodel(child, :archival_object, params[:repo_id]).to_hash})
  # end


  # Endpoint.get('/repositories/:repo_id/archival_objects')
  #   .description("Get a list of Archival Objects for a Repository")
  #   .params(["repo_id", :repo_id])
  #   .returns([200, "[(:archival_object)]"]) \
  # do
  #   handle_listing(ArchivalObject, :archival_object, :repo_id => params[:repo_id])
  # end

end
