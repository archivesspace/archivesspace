class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/families')
    .description("Create a family agent")
    .params(["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(AgentFamily, :agent)
  end


  Endpoint.get('/agents/families')
    .description("List all family agents")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:agent_family)]"]) \
  do
    handle_listing(AgentFamily, params)
  end


  Endpoint.post('/agents/families/:agent_id')
    .description("Update a family agent")
    .params(["agent_id", Integer, "The ID of the agent to update"],
            ["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(AgentFamily, :agent_id, :agent)
  end


  Endpoint.get('/agents/families/:id')
    .description("Get a family by ID")
    .params(["id", Integer, "ID of the family agent"],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    json_response(resolve_references(AgentFamily.to_jsonmodel(AgentFamily.get_or_die(params[:id])),
                                     params[:resolve]))
  end

  Endpoint.delete('/agents/families/:id')
    .description("Delete an agent family")
    .params(["id", Integer, "ID of the family agent"])
    .permissions([:delete_agent_record])
    .returns([200, :deleted]) \
  do
    handle_delete(AgentFamily, params[:id])
  end

end
