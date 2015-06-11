class ArchivesSpaceService < Sinatra::Base

  
  Endpoint.post('/repositories/:repo_id/default_values/:record_type')
    .description("Save defaults for a record type")
    .params(["default_values", JSONModel(:default_values), "The default values set", :body => true],
            ["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:manage_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    obj = DefaultValues.create_or_update(params[:default_values], params[:repo_id], params[:record_type])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/default_values/:record_type')
    .description("Get default values for a record type")
    .params(["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:view_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    id = "#{params[:repo_id]}_#{params[:record_type]}"
    json = DefaultValues.to_jsonmodel(id)

    json_response(json)
  end



end
