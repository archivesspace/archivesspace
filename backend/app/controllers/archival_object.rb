class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/archival_objects')
    .description("Create an Archival Object")
    .params(["archival_object", JSONModel(:archival_object), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(ArchivalObject, params[:archival_object])
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id')
    .description("Update an Archival Object")
    .params(["id", :id],
            ["archival_object", JSONModel(:archival_object), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(ArchivalObject, params[:id], params[:archival_object])
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/parent')
    .description("Set the parent/position of an Archival Object in a tree")
    .params(["id", :id],
            ["parent", Integer, "The parent of this node in the tree", :optional => true],
            ["position", Integer, "The position of this node in the tree", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    obj = ArchivalObject.get_or_die(params[:id])
    obj.set_parent_and_position(params[:parent], params[:position])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id')
    .description("Get an Archival Object by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:archival_object)"],
             [404, "Not found"]) \
  do
    json = ArchivalObject.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id/children')
    .description("Get the children of an Archival Object")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "a list of archival object references"],
             [404, "Not found"]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    json_response(ao.children.map {|child|
                    ArchivalObject.to_jsonmodel(child)
                  })
  end


  Endpoint.get('/repositories/:repo_id/archival_objects/:id/previous')
    .description("Get the previous record in the tree for an Archival Object")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:archival_object)"],
             [404, "No previous node"]) \
  do
    ao = ArchivalObject.get_or_die(params[:id]).previous_node

    json_response(ArchivalObject.to_jsonmodel(ao))
  end


  Endpoint.get('/repositories/:repo_id/archival_objects')
    .description("Get a list of Archival Objects for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:archival_object)]"]) \
  do
    handle_listing(ArchivalObject, params)
  end

  Endpoint.delete('/repositories/:repo_id/archival_objects/:id')
    .description("Delete an Archival Object")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(ArchivalObject, params[:id])
  end

end
