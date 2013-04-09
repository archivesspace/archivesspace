class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/families')
    .description("Create a family agent")
    .params(["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .nopermissionsyet
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(AgentFamily, :agent)
  end


  Endpoint.get('/agents/families')
    .description("List all family agents")
    .params(*Endpoint.pagination)
    .nopermissionsyet
    .returns([200, "[(:agent_family)]"]) \
  do
    handle_listing(AgentFamily, params[:page], params[:page_size], params[:modified_since])
  end


  Endpoint.post('/agents/families/:agent_id')
    .description("Update a family agent")
    .params(["agent_id", Integer, "The ID of the agent to update"],
            ["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .nopermissionsyet
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(AgentFamily, :agent_id, :agent)
  end


  Endpoint.get('/agents/families/:id')
    .description("Get a family by ID")
    .params(["id", Integer, "ID of the family agent"],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .nopermissionsyet
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    json_response(resolve_references(AgentFamily.to_jsonmodel(AgentFamily.get_or_die(params[:id])),
                                     params[:resolve]))
  end

end
