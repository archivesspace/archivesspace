class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/digital_objects/:id')
    .description("Get a Digital Object")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    json = DigitalObject.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.post('/repositories/:repo_id/digital_objects')
    .description("Create a Digital Object")
    .params(["digital_object", JSONModel(:digital_object), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(DigitalObject, params[:digital_object])
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id')
    .description("Update a Digital Object")
    .params(["id", :id],
            ["digital_object", JSONModel(:digital_object), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(DigitalObject, params[:id], params[:digital_object])
  end


  Endpoint.get('/repositories/:repo_id/digital_objects')
    .description("Get a list of Digital Objects for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:digital_object)]"]) \
  do
    handle_listing(DigitalObject, params)
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree')
    .description("Get a Digital Object tree")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    digital_object = DigitalObject.get_or_die(params[:id])

    json_response(digital_object.tree)
  end


  Endpoint.delete('/repositories/:repo_id/digital_objects/:id')
    .description("Delete a Digital Object")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(DigitalObject, params[:id])
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/publish')
  .description("Publish a digital object and all its sub-records and components")
  .params(["id", :id],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :updated],
           [400, :error]) \
  do
    digital_object = DigitalObject.get_or_die(params[:id])
    digital_object.publish!

    updated_response(digital_object)
  end

end
