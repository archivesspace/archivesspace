class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/collection_management')
    .description("Get a list of Collection Management Records for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:collection_management)]"]) \
  do
    handle_listing(CollectionManagement, params)
  end


  Endpoint.get('/repositories/:repo_id/collection_management/:collection_management_id')
    .description("Get a Collection Management Record by ID")
    .params(["collection_management_id", Integer, "The Collection Management ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true]
            )
    .permissions([:view_repository])
    .returns([200, "(:collection_management)"],
             [404, '{"error":"CollectionManagement not found"}']) \
  do
    json = CollectionManagement.to_jsonmodel(params[:collection_management_id])

    json_response(resolve_references(json, params[:resolve]))
  end

end
