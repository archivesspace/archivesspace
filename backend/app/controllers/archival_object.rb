class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/archival_objects')
    .description("Create an Archival Object")
    .params(["archival_object", JSONModel(:archival_object), "The archival_object to create", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, :created]) \
  do
    ao = ArchivalObject.create_from_json(params[:archival_object],
                                         :repo_id => params[:repo_id])

    created_response(ao[:id], params[:archival_object]._warnings)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:archival_object_id')
    .params(["archival_object_id", Integer, "The archival object ID to update"],
            ["archival_object", JSONModel(:archival_object), "The archival object data to update", :body => true])
    .returns([200, "OK"]) \
  do
    ao = ArchivalObject.get_or_die(params[:archival_object_id])
    ao.update_from_json(params[:archival_object])

    json_response({:status => "Updated", :id => ao[:id]})
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id')
    .description("Get an Archival Object by ID")
    .params(["archival_object_id", Integer, "The archival object ID"],
            ["repo_id", Integer, "The repository ID"],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, JSONModel(:archival_object)]) \
  do
    json = ArchivalObject.to_jsonmodel(params[:archival_object_id], :archival_object)

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:archival_object_id/children')
    .params(["archival_object_id", Integer, "The archival object ID"],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    ao = ArchivalObject.get_or_die(params[:archival_object_id])
    json_response(ao.children.map {|child|
                    ArchivalObject.to_jsonmodel(child, :archival_object).to_hash})
  end


  Endpoint.get('/repositories/:repo_id/archival_objects')
    .params(["repo_id", Integer, "The ID of the repository containing the archival object"])
    .returns([200, "OK"]) \
  do
    json_response(ArchivalObject.filter({:repo_id => params[:repo_id]}).
                                 collect {|ao| ArchivalObject.to_jsonmodel(ao, :archival_object).to_hash})
  end

end
