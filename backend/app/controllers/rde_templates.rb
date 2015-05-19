class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/rde_templates')
    .description("Create an RDE template")
    .params(["rde_template", JSONModel(:rde_template), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, :created],
             [400, :error]) \
  do
    check_permissions(params)
    handle_create(RdeTemplate, params[:rde_template])
  end


  Endpoint.get('/repositories/:repo_id/rde_templates/:id')
    .description("Get an RDE template record")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:rde_template)"]) \
  do
    json = RdeTemplate.to_jsonmodel(params[:id])

    json_response(json)
  end


  Endpoint.get('/repositories/:repo_id/rde_templates')
    .description("Get a list of RDE Templates")
    .params(["repo_id", :repo_id])
    .permissions([])
    .returns([200, "[(:rde_template)]"]) \
  do
    handle_unlimited_listing(RdeTemplate)
  end


  Endpoint.delete('/repositories/:repo_id/rde_templates/:id')
    .description("Delete an RDE Template")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_rde_templates])
    .returns([200, :deleted]) \
  do 
    handle_delete(RdeTemplate, params[:id])
  end


  def check_permissions(params)
    if !current_user.can?(:manage_rde_templates)
      raise AccessDeniedException.new
    end
  end
end
