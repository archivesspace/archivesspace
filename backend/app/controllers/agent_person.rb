class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/people')
    .description("Create a person agent")
    .params(["agent", JSONModel(:agent_person), "The person to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    agent = AgentPerson.create_from_json(params[:agent])
    created_response(agent[:id])
  end


  Endpoint.post('/agents/people/:agent_id')
    .description("Update a person agent")
    .params(["agent_id", Integer, "The ID of the agent to update"],
            ["agent", JSONModel(:agent_person), "The person to create", :body => true])
    .returns([200, :updated],
             [400, :error]) \
  do
    agent = AgentPerson.get_or_die(params[:agent_id])
    agent.update_from_json(params[:agent])

    json_response({:status => "Updated", :id => agent[:id]})
  end


  Endpoint.get('/agents/people/:id')
    .description("Get a person by ID")
    .params(["id", Integer, "ID of the person agent"])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    AgentPerson.to_jsonmodel(AgentPerson.get_or_die(params[:id]),
                       :agent_person).to_json
  end


  # Endpoint.get('/agents')
  #   .description("Get a list of Agents")
  #   .returns([200, "[(:agent)]"]) \
  # do
  #   json_response(Agent.collect {|agent|
  #                   Agent.to_jsonmodel(agent, :agent).to_hash
  #                 })
  # end

end
