class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/classifications')
    .description("Create a Classification")
    .params(["classification", JSONModel(:classification), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Classification, params[:classification])
  end


  Endpoint.get('/repositories/:repo_id/classifications/:id')
    .description("Get a Classification")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:classification)"]) \
  do
    json = Classification.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/classifications/:id/tree')
    .description("Get a Classification tree")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    classification = Classification.get_or_die(params[:id])

    json_response(classification.tree)
  end


  Endpoint.post('/repositories/:repo_id/classifications/:id')
    .description("Update a Classification")
    .params(["id", :id],
            ["classification", JSONModel(:classification), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Classification, params[:id], params[:classification])
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


  Endpoint.delete('/repositories/:repo_id/classifications/:id')
    .description("Delete a Classification")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_classification_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Classification, params[:id])
  end
end
