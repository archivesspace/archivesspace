class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/software')
    .description("Create a software agent")
    .params(["agent", JSONModel(:agent_software), "The software to create", :body => true])
    .nopermissionsyet
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(AgentSoftware, :agent)
  end


  Endpoint.get('/agents/software')
    .description("List all software agents")
    .params(*Endpoint.pagination)
    .nopermissionsyet
    .returns([200, "[(:agent_software)]"]) \
  do
    handle_listing(AgentSoftware, params[:page], params[:page_size], params[:modified_since])
  end


  Endpoint.post('/agents/software/:agent_id')
    .description("Update a software agent")
    .params(["agent_id", Integer, "The ID of the software to update"],
            ["agent", JSONModel(:agent_software), "The software to create", :body => true])
    .nopermissionsyet
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(AgentSoftware, :agent_id, :agent)
  end


  Endpoint.get('/agents/software/:id')
    .description("Get a software by ID")
    .params(["id", Integer, "ID of the software agent"],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .nopermissionsyet
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    json_response(resolve_references(AgentSoftware.to_jsonmodel(AgentSoftware.get_or_die(params[:id])),
                                     params[:resolve]))
  end

end
