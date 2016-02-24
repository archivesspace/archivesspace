class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/digital_object_components')
    .description("Create an Digital Object Component")
    .params(["digital_object_component", JSONModel(:digital_object_component), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(DigitalObjectComponent, params[:digital_object_component])
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id')
    .description("Update an Digital Object Component")
    .params(["id", :id],
            ["digital_object_component", JSONModel(:digital_object_component), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(DigitalObjectComponent, params[:id], params[:digital_object_component])
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/parent')
    .description("Set the parent/position of an Digital Object Component in a tree")
    .params(["id", :id],
            ["parent", Integer, "The parent of this node in the tree", :optional => true],
            ["position", Integer, "The position of this node in the tree", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    obj = DigitalObjectComponent.get_or_die(params[:id])
    obj.update_position_only(params[:parent], params[:position])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components/:id')
    .description("Get an Digital Object Component by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:digital_object_component)"],
             [404, "Not found"]) \
  do
    json = DigitalObjectComponent.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components/:id/children')
    .description("Get the children of an Digital Object Component")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:digital_object_component)]"],
             [404, "Not found"]) \
  do
    digital_object = DigitalObjectComponent.get_or_die(params[:id])
    json_response(digital_object.children.map {|child|
                    DigitalObjectComponent.to_jsonmodel(child)
                  })
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components')
    .description("Get a list of Digital Object Components for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:digital_object_component)]"]) \
  do
    handle_listing(DigitalObjectComponent, params)
  end


  Endpoint.delete('/repositories/:repo_id/digital_object_components/:id')
    .description("Delete a Digital Object Component")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(DigitalObjectComponent, params[:id])
  end

end
