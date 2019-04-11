require_relative 'search'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/top_containers/search')
  .description("Search for top containers")
  .params(["repo_id", :repo_id],
          *BASE_SEARCH_PARAMS)
  .permissions([:view_repository])
  .returns([200, "[(:top_container)]"]) \
  do
    search_params = params.merge(:type => ['top_container'])

    [
      200,
      {'Content-Type' => 'application/json'},
      Enumerator.new do |y|
        # Need to use the captured 'search_params' here because Sinatra will
        # have reset 'params' to the original version by the time the enumerator
        # runs.
        TopContainer.search_stream(search_params, search_params[:repo_id]) do |response|
          y << response.body
        end
      end
    ]

  end


  Endpoint.post('/repositories/:repo_id/top_containers/:id')
    .description("Update a top container")
    .params(["id", :id],
            ["top_container", JSONModel(:top_container), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_container_record])
    .returns([200, :updated]) \
  do
    handle_update(TopContainer, params[:id], params[:top_container])
  end


  Endpoint.post('/repositories/:repo_id/top_containers')
    .description("Create a top container")
    .params(["top_container", JSONModel(:top_container), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_container_record])
    .returns([200, :created]) \
  do
    handle_create(TopContainer, params[:top_container])
  end


  Endpoint.get('/repositories/:repo_id/top_containers')
    .description("Get a list of TopContainers for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:top_container)]"]) \
  do
    handle_listing(TopContainer, params)
  end


  Endpoint.get('/repositories/:repo_id/top_containers/:id')
    .description("Get a top container by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:top_container)"]) \
  do
    json = TopContainer.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/top_containers/:id')
    .description("Delete a top container")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :deleted]) \
  do
    handle_delete(TopContainer, params[:id])
  end


  Endpoint.post('/repositories/:repo_id/top_containers/batch/ils_holding_id')
    .description("Update ils_holding_id for a batch of top containers")
    .params(["ids", [Integer]],
            ["ils_holding_id", String, "Value to set for ils_holding_id"],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    result = TopContainer.batch_update(params[:ids], :ils_holding_id => params[:ils_holding_id])
    json_response(result)
  end


  Endpoint.post('/repositories/:repo_id/top_containers/batch/container_profile')
    .description("Update container profile for a batch of top containers")
    .params(["ids", [Integer]],
            ["container_profile_uri", String, "The uri of the container profile"],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    result = TopContainer.bulk_update_container_profile(params[:ids], params[:container_profile_uri])
    json_response(result)
  end


  Endpoint.post('/repositories/:repo_id/top_containers/batch/location')
    .description("Update location for a batch of top containers")
    .example('shell') do
      <<-SHELL
 curl -H "X-ArchivesSpace-Session: $SESSION" \\
   -d 'ids[]=[1,2,3,4,5]' \\
   -d 'location_uri=locations/1234' \\
   "http://localhost:8089/repositories/2/top_containers/batch/location"
      SHELL
    end
    .example('python') do
      <<-PYTHON
client = ASnakeClient()
client.post('repositories/2/top_containers/batch/location',
            params={ 'ids': [1,2,3,4,5],
                     'location_uri': 'locations/1234' })
      PYTHON
    end
    .documentation do
      <<-DOCS
This route takes the `ids` of one or more containers, and associates the containers
with the location referenced by `location_uri`.
      DOCS
    end
    .params(["ids", [Integer]],
            ["location_uri", String, "The uri of the location"],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    result = TopContainer.bulk_update_location(params[:ids], params[:location_uri])
    json_response(result)
  end


  Endpoint.post('/repositories/:repo_id/top_containers/bulk/barcodes')
  .description("Bulk update barcodes")
  .params(["barcode_data", String, "JSON string containing barcode data {uri=>barcode}", :body => true],
          ["repo_id", :repo_id])
  .permissions([:manage_container_record])
  .returns([200, :updated]) \
  do
    begin
      updated = TopContainer.bulk_update_barcodes(ASUtils.json_parse(params[:barcode_data]))
      json_response(:updated => updated)
    rescue Sequel::ValidationFailed => e
      json_response({:error => e.errors, :uri => e.model.uri}, 400)
    end
  end


  Endpoint.post('/repositories/:repo_id/top_containers/bulk/locations')
  .description("Bulk update locations")
  .params(["location_data", String, "JSON string containing location data {container_uri=>location_uri}", :body => true],
          ["repo_id", :repo_id])
  .permissions([:manage_container_record])
  .returns([200, :updated]) \
  do
    begin
      result = TopContainer.bulk_update_locations(ASUtils.json_parse(params[:location_data]))
      json_response(result)
    rescue Sequel::ValidationFailed => e
      json_response({:error => e.errors, :uri => e.model.uri}, 400)
    end
  end

end
