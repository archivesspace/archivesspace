class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/assessments/:id')
    .description("Update an Assessment")
    .params(["id", :id],
            ["assessment", JSONModel(:assessment), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_assessment_record])
    .returns([200, :updated]) \
  do
    handle_update(Assessment, params[:id], params[:assessment])
  end


  Endpoint.post('/repositories/:repo_id/assessments')
    .description("Create an Assessment")
    .params(["assessment", JSONModel(:assessment), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_assessment_record])
    .returns([200, :created]) \
  do
    handle_create(Assessment, params[:assessment])
  end


  Endpoint.get('/repositories/:repo_id/assessments')
    .description("Get a list of Assessments for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:assessment)]"]) \
  do
    handle_listing(Assessment, params)
  end


  Endpoint.get('/repositories/:repo_id/assessments/:id')
    .description("Get an Assessment by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:assessment)"]) \
  do
    json = Assessment.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/assessments/:id')
    .description("Delete an Assessment")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_assessment_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Assessment, params[:id])
  end

end
