class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/container_profiles/:id')
    .description("Update a Container Profile")
    .params(["id", :id],
            ["container_profile", JSONModel(:container_profile), "The updated record", :body => true])
    .permissions([:update_container_profile_record])
    .returns([200, :updated]) \
  do
    handle_update(ContainerProfile, params[:id], params[:container_profile])
  end


  Endpoint.post('/container_profiles')
    .description("Create a Container_Profile")
    .params(["container_profile", JSONModel(:container_profile), "The record to create", :body => true])
    .permissions([:update_container_profile_record])
    .returns([200, :created]) \
  do
    handle_create(ContainerProfile, params[:container_profile])
  end


  Endpoint.get('/container_profiles')
    .description("Get a list of Container Profiles")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:container_profile)]"]) \
  do
    handle_listing(ContainerProfile, params)
  end


  Endpoint.get('/container_profiles/:id')
    .description("Get a Container Profile by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:container_profile)"]) \
  do
    json = ContainerProfile.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/container_profiles/:id')
    .description("Delete an Container Profile")
    .params(["id", :id])
    .permissions([:update_container_profile_record])
    .returns([200, :deleted]) \
  do
    handle_delete(ContainerProfile, params[:id])
  end

end
