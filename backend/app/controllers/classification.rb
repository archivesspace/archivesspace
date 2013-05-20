class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/classifications')
    .description("Create a Classification")
    .params(["classification", JSONModel(:classification), "The classification to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Classification, :classification)
  end


  Endpoint.get('/repositories/:repo_id/classifications/:classification_id')
    .description("Get a Classification")
    .params(["classification_id", Integer, "The ID of the classification to retrieve"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:classification)"]) \
  do
    json = Classification.to_jsonmodel(params[:classification_id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/classifications/:classification_id/tree')
    .description("Get a Classification tree")
    .params(["classification_id", Integer, "The ID of the classification to retrieve"],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    classification = Classification.get_or_die(params[:classification_id])

    json_response(classification.tree)
  end


  Endpoint.post('/repositories/:repo_id/classifications/:classification_id')
    .description("Update a Classification")
    .params(["classification_id", Integer, "The ID of the classification to retrieve"],
            ["classification", JSONModel(:classification), "The classification to update", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Classification, :classification_id, :classification)
  end


  Endpoint.get('/repositories/:repo_id/classifications')
    .description("Get a list of Classifications for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:classification)]"]) \
  do
    handle_listing(Classification, params)
  end


  Endpoint.delete('/repositories/:repo_id/classifications/:classification_id')
    .description("Delete a Classification")
    .params(["classification_id", Integer, "The classification ID to delete"],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Classification, params[:classification_id])
  end
end
