class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/locations/batch')
  .description("Create a Batch of Locations")
  .params(["dry_run", String, "If true, don't create the locations, just list them", :optional => true],
          ["location_batch", JSONModel(:location_batch), "The location batch data to generate all locations", :body => true],
          ["repo_id", :repo_id])
  .permissions([:update_location_record])
  .returns([200, :updated]) \
  do
    batch = params[:location_batch]

    if params[:dry_run] == "true"
      result = Location.titles_for_batch(batch)
    else
      result = Location.create_for_batch(batch).map {|obj| obj.uri}
    end

    json_response(result)
  end

  Endpoint.post('/repositories/:repo_id/locations/:id')
  .description("Update a Location")
  .params(["id", :id],
          ["location", JSONModel(:location), "The location data to update", :body => true],
          ["repo_id", :repo_id])
    .permissions([:update_location_record])
  .returns([200, :updated]) \
  do
    handle_update(Location, :id, :location)
  end

  Endpoint.post('/repositories/:repo_id/locations')
    .description("Create a Location")
    .params(["location", JSONModel(:location), "The location data to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_location_record])
    .returns([200, :created]) \
  do
    handle_create(Location, :location)
  end


  Endpoint.get('/repositories/:repo_id/locations')
    .description("Get a list of locations")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:location)]"]) \
  do
    handle_listing(Location, params)
  end


  Endpoint.get('/repositories/:repo_id/locations/:id')
    .description("Get a Location by ID")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:location)"]) \
  do
    json_response(Location.to_jsonmodel(params[:id]))
  end

end
