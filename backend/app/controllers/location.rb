class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/locations/:location_id')
  .description("Update a Location")
  .params(["location_id", Integer, "The ID of the location to update"],
          ["location", JSONModel(:location), "The location data to update", :body => true],
          ["repo_id", :repo_id])
  .returns([200, :updated]) \
  do
    handle_update(Location, :location_id, :location,
                  :repo_id => params[:repo_id])
  end

  Endpoint.post('/repositories/:repo_id/locations')
    .description("Create a Location")
    .params(["location", JSONModel(:location), "The location data to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created]) \
  do
    handle_create(Location, :location)
  end


  Endpoint.get('/repositories/:repo_id/locations')
    .description("Get a list of locations")
    .params(["repo_id", :repo_id])
    .returns([200, "[(:location)]"]) \
  do
    handle_listing(Location, :location, :repo_id => params[:repo_id])
  end


  Endpoint.get('/repositories/:repo_id/locations/:location_id')
    .description("Get a Location by ID")
    .params(["location_id", Integer, "The Location ID"],
            ["repo_id", :repo_id])
    .returns([200, "(:location)"]) \
  do
    json_response(Location.to_jsonmodel(params[:location_id], :location, params[:repo_id]))
  end

end
