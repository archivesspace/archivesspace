class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/archival_objects')
    .description("Create an Archival Object")
    .params(["archival_object", JSONModel(:archival_object), "The Archival Object to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :created],
             [400, :error],
             [409, '{"error":{"[:root_record_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}']) \
  do
    handle_create(ArchivalObject, :archival_object)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:archival_object_id')
    .description("Update an Archival Object")
    .params(["archival_object_id", Integer, "The Archival Object ID to update"],
            ["archival_object", JSONModel(:archival_object), "The Archival Object data to update", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :updated],
             [400, :error],
             [409, '{"error":{"[:root_record_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}']) \
  do
    handle_update(ArchivalObject, :archival_object_id, :archival_object)
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id')
    .description("Get an Archival Object by ID")
    .params(["archival_object_id", Integer, "The Archival Object ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:archival_object)"],
             [404, '{"error":"ArchivalObject not found"}']) \
  do
    json = ArchivalObject.to_jsonmodel(params[:archival_object_id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id/children')
    .description("Get the children of an Archival Object")
    .params(["archival_object_id", Integer, "The Archival Object ID"],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "a list of archival object references"],
             [404, '{"error":"ArchivalObject not found"}']) \
  do
    ao = ArchivalObject.get_or_die(params[:archival_object_id])
    json_response(ao.children.map {|child|
      ArchivalObject.to_jsonmodel(child)})
  end


  Endpoint.get('/repositories/:repo_id/archival_objects')
    .description("Get a list of Archival Objects for a Repository")
    .params(["repo_id", :repo_id],
            *Endpoint.pagination)
    .permissions([:view_repository])
    .returns([200, "[(:archival_object)]"]) \
  do
    handle_listing(ArchivalObject, params[:page], params[:page_size], params[:modified_since])
  end

end
