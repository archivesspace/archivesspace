class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/agents')
    .description("Get all agent records")
    .returns([200, "[(:agent)]"]) \
  do
    all_people = AgentPerson.all.collect {|agent| AgentPerson.to_jsonmodel(agent, :agent_person).to_hash}
    all_families = AgentFamily.all.collect {|agent| AgentFamily.to_jsonmodel(agent, :agent_family).to_hash}

    json_response(all_people.concat(all_families))
  end

end
