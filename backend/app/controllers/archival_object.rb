class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/archival_objects')
    .description("Create an Archival Object")
    .params(["archival_object", JSONModel(:archival_object), "The Archival Object to create", :body => true],
            ["repo_id", Integer, "The Repository ID"])
    .returns([200, :created],
             [400, :error],
             [409, '{"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}']) \
  do
    ao = ArchivalObject.create_from_json(params[:archival_object],
                                         :repo_id => params[:repo_id])

    created_response(ao, params[:archival_object]._warnings)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:archival_object_id')
    .description("Update an Archival Object")
    .params(["archival_object_id", Integer, "The Archival Object ID to update"],
            ["archival_object", JSONModel(:archival_object), "The Archival Object data to update", :body => true],
            ["repo_id", Integer, "The Repository ID"])
    .returns([200, :updated],
             [400, :error],
             [409, '{"error":{"[:resource_id, :ref_id]":["An Archival Object Ref ID must be unique to its resource"]}}']) \
  do
    ao = ArchivalObject.get_or_die(params[:archival_object_id], params[:repo_id])
    ao.update_from_json(params[:archival_object])

    json_response({:status => "Updated", :id => ao[:id]})
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id')
    .description("Get an Archival Object by ID")
    .params(["archival_object_id", Integer, "The Archival Object ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, "(:archival_object)"],
             [404, '{"error":"ArchivalObject not found"}']) \
  do
    json = ArchivalObject.to_jsonmodel(params[:archival_object_id], :archival_object, params[:repo_id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id/children')
    .description("Get the children of an Archival Object")
    .params(["archival_object_id", Integer, "The Archival Object ID"],
            ["repo_id", Integer, "The Repository ID"])
    .returns([200, "[(:archival_object)]"],
             [404, '{"error":"ArchivalObject not found"}']) \
  do
    ao = ArchivalObject.get_or_die(params[:archival_object_id], params[:repo_id])
    json_response(ao.children.map {|child|
                    ArchivalObject.to_jsonmodel(child, :archival_object).to_hash})
  end


  Endpoint.get('/repositories/:repo_id/archival_objects')
    .description("Get a list of Archival Objects for a Repository")
    .params(["repo_id", Integer, "The Repository ID"])
    .returns([200, "[(:archival_object)]"]) \
  do
    json_response(ArchivalObject.filter({:repo_id => params[:repo_id]}).
                  collect {|ao| ArchivalObject.to_jsonmodel(ao, :archival_object).to_hash})
  end

end
