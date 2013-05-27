class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/software')
    .description("Create a software agent")
    .params(["agent", JSONModel(:agent_software), "The software to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(AgentSoftware, :agent)
  end


  Endpoint.get('/agents/software')
    .description("List all software agents")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:agent_software)]"]) \
  do
    handle_listing(AgentSoftware, params)
  end


  Endpoint.post('/agents/software/:agent_id')
    .description("Update a software agent")
    .params(["agent_id", Integer, "The ID of the software to update"],
            ["agent", JSONModel(:agent_software), "The software to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(AgentSoftware, :agent_id, :agent)
  end


  Endpoint.get('/agents/software/:id')
    .description("Get a software agent by ID")
    .params(["id", Integer, "ID of the software agent"],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .permissions([])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    json_response(resolve_references(AgentSoftware.to_jsonmodel(AgentSoftware.get_or_die(params[:id])),
                                     params[:resolve]))
  end

  Endpoint.delete('/agents/software/:id')
    .description("Delete a software agent")
    .params(["id", Integer, "ID of the software agent"])
    .permissions([:delete_agent_record])
    .returns([200, :deleted]) \
  do
    handle_delete(AgentSoftware, params[:id])
  end

end
