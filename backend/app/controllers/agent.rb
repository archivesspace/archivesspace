class ArchivesSpaceService < Sinatra::Base

  @@agent_types = [[AgentPerson, :agent_person],
                   [AgentFamily, :agent_family],
                   [AgentCorporateEntity, :agent_corporate_entity],
                   [AgentSoftware, :agent_software]]

  Endpoint.get('/agents')
    .description("Get all agent records")
    .returns([200, "[(:agent)]"]) \
  do
    agents = @@agent_types.map do |model, type|
      model.all.collect {|agent| model.to_jsonmodel(agent, type, :none).to_hash}
    end

    json_response(agents.flatten)
  end


  Endpoint.get('/agents/by-name')
    .description("Get all agent records by their sort name")
    .params(["q", /[\w0-9 -.]/, "The name prefix to match"])
    .returns([200, "[(:agent)]"]) \
  do
    json_response(@@agent_types.map {|agent_model, agent_type|
                    agent_model.records_matching(params[:q]).map {|agent|
                      agent_model.to_jsonmodel(agent, agent_type, :none).to_hash
                    }
                  }.flatten)
  end

end
