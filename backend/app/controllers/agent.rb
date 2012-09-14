class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/agents')
    .description("Get all agent records")
    .returns([200, "[(:agent)]"]) \
  do
    agents = [[AgentPerson, :agent_person],
              [AgentFamily, :agent_family]].map do |model, type|

      model.all.collect {|agent| model.to_jsonmodel(agent, type).to_hash}
    end

    json_response(agents.flatten)
  end

end
