class ArchivesSpaceService < Sinatra::Base

  # Collection management records are a freakish hybrid of top-level and nested
  # records.  As such, they've historically had no API endpoints, but we need
  # one so that the frontend's URI resolver can find a collection management's
  # containing record given its URI.
  #
  Endpoint.get('/repositories/:repo_id/collection_management/:id')
    .description("Get a Collection Management Record by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:collection_management)"]) \
  do
    json = CollectionManagement.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end

end
