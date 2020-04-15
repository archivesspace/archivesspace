require_relative 'search'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/location_profiles/:id')
    .description("Update a Location Profile")
    .params(["id", :id],
            ["location_profile", JSONModel(:location_profile), "The updated record", :body => true])
    .permissions([:update_location_profile_record])
    .returns([200, :updated]) \
  do
    handle_update(LocationProfile, params[:id], params[:location_profile])
  end


  Endpoint.post('/location_profiles')
    .description("Create a Location_Profile")
    .params(["location_profile", JSONModel(:location_profile), "The record to create", :body => true])
    .permissions([:update_location_profile_record])
    .returns([200, :created]) \
  do
    handle_create(LocationProfile, params[:location_profile])
  end


  Endpoint.get('/location_profiles')
    .description("Get a list of Location Profiles")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:location_profile)]"]) \
  do
    handle_listing(LocationProfile, params)
  end


  Endpoint.get('/location_profiles/:id')
    .description("Get a Location Profile by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:location_profile)"]) \
  do
    json = LocationProfile.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/location_profiles/:id')
    .description("Delete an Location Profile")
    .params(["id", :id])
    .permissions([:update_location_profile_record])
    .returns([200, :deleted]) \
  do
    handle_delete(LocationProfile, params[:id])
  end

  Endpoint.get('/search/location_profile')
    .description("Search across Location Profiles")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paged(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['location_profile']), nil))
  end

end
