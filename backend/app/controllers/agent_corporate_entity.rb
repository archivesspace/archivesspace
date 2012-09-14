class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/corporate_entities')
    .description("Create a corporate entity agent")
    .params(["agent", JSONModel(:agent_corporate_entity), "The corporate entity to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    agent = AgentCorporateEntity.create_from_json(params[:agent])
    created_response(agent, params[:agent])
  end


  Endpoint.post('/agents/corporate_entities/:agent_id')
    .description("Update a corporate entity agent")
    .params(["agent_id", Integer, "The ID of the agent to update"],
            ["agent", JSONModel(:agent_corporate_entity), "The corporate entity to create", :body => true])
    .returns([200, :updated],
             [400, :error]) \
  do
    agent = AgentCorporateEntity.get_or_die(params[:agent_id])
    agent.update_from_json(params[:agent])

    json_response({:status => "Updated", :id => agent[:id]})
  end


  Endpoint.get('/agents/corporate_entities/:id')
    .description("Get a corporate entity by ID")
    .params(["id", Integer, "ID of the corporate entity agent"])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    AgentCorporateEntity.to_jsonmodel(AgentCorporateEntity.get_or_die(params[:id]),
                       :agent_corporate_entity).to_json
  end

end
