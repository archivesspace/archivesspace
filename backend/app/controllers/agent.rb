class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/agents')
    .description("Get all agent records")
    .returns([200, "[(:agent)]"]) \
  do
    agents = AgentManager.type_to_model_map.map {|type, model|
      model.all.collect {|agent| model.to_jsonmodel(agent, type, :none).to_hash}
    }

    json_response(agents.flatten)
  end


  Endpoint.get('/agents/by-name')
    .description("Get all agent records by their sort name")
    .params(["q", /[\w0-9 -.]/, "The name prefix to match"])
    .returns([200, "[(:agent)]"]) \
  do
    json_response(AgentManager.type_to_model_map.map {|agent_type, agent_model|
                    agent_model.agents_matching(params[:q], 10).map {|agent|
                      agent_model.to_jsonmodel(agent, agent_type, :none).to_hash
                    }
                  }.flatten)
  end

end
