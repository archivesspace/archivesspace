class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/families')
    .description("Create a family agent")
    .params(["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    agent = AgentFamily.create_from_json(params[:agent])

    created_response(agent, params[:agent])
  end


  Endpoint.post('/agents/families/:agent_id')
    .description("Update a family agent")
    .params(["agent_id", Integer, "The ID of the agent to update"],
            ["agent", JSONModel(:agent_family), "The family to create", :body => true])
    .returns([200, :updated],
             [400, :error]) \
  do
    agent = AgentFamily.get_or_die(params[:agent_id])
    agent.update_from_json(params[:agent])

    json_response({:status => "Updated", :id => agent[:id]})
  end


  Endpoint.get('/agents/families/:id')
    .description("Get a family by ID")
    .params(["id", Integer, "ID of the family agent"])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    AgentFamily.to_jsonmodel(AgentFamily.get_or_die(params[:id]),
                       :agent_family).to_json
  end

end
