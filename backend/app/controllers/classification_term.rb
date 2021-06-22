class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/classification_terms')
    .description("Create a Classification Term")
    .params(["classification_term", JSONModel(:classification_term), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(ClassificationTerm, params[:classification_term])
  end


  Endpoint.post('/repositories/:repo_id/classification_terms/:id')
    .description("Update a Classification Term")
    .params(["id", :id],
            ["classification_term", JSONModel(:classification_term), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(ClassificationTerm, params[:id], params[:classification_term])
  end


  Endpoint.post('/repositories/:repo_id/classification_terms/:id/parent')
    .description("Set the parent/position of a Classification Term in a tree")
    .params(["id", :id],
            ["parent", Integer, "The parent of this node in the tree", :optional => true],
            ["position", Integer, "The position of this node in the tree", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    obj = ClassificationTerm.get_or_die(params[:id])
    obj.set_parent_and_position(params[:parent], params[:position])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/classification_terms/:id')
    .description("Get a Classification Term by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:classification_term)"],
             [404, "Not found"]) \
  do
    json = ClassificationTerm.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/classification_terms/:id/children')
    .description("Get the children of a Classification Term")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "a list of classification term references"],
             [404, "Not found"]) \
  do
    ao = ClassificationTerm.get_or_die(params[:id])
    json_response(ao.children.map {|child|
                    ClassificationTerm.to_jsonmodel(child)
                  })
  end


  Endpoint.get('/repositories/:repo_id/classification_terms')
    .description("Get a list of Classification Terms for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:classification_term)]"]) \
  do
    handle_listing(ClassificationTerm, params)
  end


  Endpoint.delete('/repositories/:repo_id/classification_terms/:id')
    .description("Delete a Classification Term")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_classification_record])
    .returns([200, :deleted]) \
  do
    handle_delete(ClassificationTerm, params[:id])
  end

end
