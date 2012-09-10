class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents')
    .description("Create an Agent")
    .params(["agent", JSONModel(:agent), "The agent to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    agent = Agent.create_from_json(params[:agent])
    created_response(agent[:id])
  end


  Endpoint.get('/agents/:id')
    .description("Get an Agent by ID")
    .params(["id", Integer, "ID of the agent"])
    .returns([200, "(:agent)"],
             [404, '{"error":"Agent not found"}']) \
  do
    Agent.to_jsonmodel(Agent.get_or_die(params[:id]),
                       :agent).to_json
  end


  Endpoint.get('/agents')
    .description("Get a list of Agents")
    .returns([200, "[(:agent)]"]) \
  do
    json_response(Agent.collect {|agent|
                    Agent.to_jsonmodel(agent, :agent).to_hash
                  })
  end

end
