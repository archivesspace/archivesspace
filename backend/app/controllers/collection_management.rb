class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/collection_management_records')
    .description("Create a Collection Management Record")
    .params(["collection_management", JSONModel(:collection_management),
             "The Collection Management record to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(CollectionManagement, :collection_management)
  end


  Endpoint.post('/repositories/:repo_id/collection_management_records/:collection_management_id')
    .description("Update a Collection Management Record")
    .params(["collection_management_id", Integer, "The Collection Management ID to update"],
            ["collection_management", JSONModel(:collection_management),
             "The collection management data to update", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :updated]) \
  do
    handle_update(CollectionManagement, :collection_management_id, :collection_management)
  end


  Endpoint.get('/repositories/:repo_id/collection_management_records')
    .description("Get a list of Collection Management Records for a Repository")
    .params(["repo_id", :repo_id],
            *Endpoint.pagination)
    .returns([200, "[(:collection_management)]"]) \
  do
    handle_listing(CollectionManagement, params[:page], params[:page_size], params[:modified_since])
  end


  Endpoint.get('/repositories/:repo_id/collection_management_records/:collection_management_id')
    .description("Get a Collection Management Record by ID")
    .params(["collection_management_id", Integer, "The Collection Management ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true]
            )
    .returns([200, "(:collection_management)"],
             [404, '{"error":"CollectionManagement not found"}']) \
  do
    json = CollectionManagement.to_jsonmodel(params[:collection_management_id])

    json_response(resolve_references(json.to_hash, params[:resolve]))
  end

end
