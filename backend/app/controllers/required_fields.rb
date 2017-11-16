class ArchivesSpaceService < Sinatra::Base

  
  Endpoint.post('/repositories/:repo_id/required_fields/:record_type')
    .description("Require fields for a record type")
    .params(["required_fields", JSONModel(:required_fields), "The fields required", :body => true],
            ["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:manage_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    obj = RequiredFields.create_or_update(params[:required_fields], params[:repo_id], params[:record_type])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/required_fields/:record_type')
    .description("Get required fields for a record type")
    .params(["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:view_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    id = "#{params[:repo_id]}_#{params[:record_type]}"
    json = RequiredFields.to_jsonmodel(id)

    json_response(json)
  end



end
