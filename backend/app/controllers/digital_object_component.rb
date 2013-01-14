class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/digital_object_components')
    .description("Create an Digital Object Component")
    .params(["digital_object_component", JSONModel(:digital_object_component), "The Digital Object Component to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(DigitalObjectComponent, :digital_object_component)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:digital_object_component_id')
    .description("Update an Digital Object Component")
    .params(["digital_object_component_id", Integer, "The Digital Object Component ID to update"],
            ["digital_object_component", JSONModel(:digital_object_component), "The Digital Object Component data to update", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_repository])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(DigitalObjectComponent, :digital_object_component_id, :digital_object_component)
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components/:digital_object_component_id')
    .description("Get an Digital Object Component by ID")
    .params(["digital_object_component_id", Integer, "The Digital Object Component ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:digital_object_component)"],
             [404, '{"error":"DigitalObjectComponent not found"}']) \
  do
    json = DigitalObjectComponent.to_jsonmodel(params[:digital_object_component_id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components/:digital_object_component_id/children')
    .description("Get the children of an Digital Object Component")
    .params(["digital_object_component_id", Integer, "The Digital Object Component ID"],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:digital_object_component)]"],
             [404, '{"error":"DigitalObjectComponent not found"}']) \
  do
    digital_object = DigitalObjectComponent.get_or_die(params[:digital_object_component_id])
    json_response(digital_object.children.map {|child|
                    DigitalObjectComponent.to_jsonmodel(child)})
  end


  Endpoint.get('/repositories/:repo_id/digital_object_components')
    .description("Get a list of Digital Object Components for a Repository")
    .params(["repo_id", :repo_id],
            *Endpoint.pagination)
    .permissions([:view_repository])
    .returns([200, "[(:digital_object_component)]"]) \
  do
    handle_listing(DigitalObjectComponent, params[:page], params[:page_size], params[:modified_since])
  end

end
