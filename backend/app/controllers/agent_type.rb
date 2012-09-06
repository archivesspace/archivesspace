class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/agent_types/:id')
    .description("Get an Agent Type by ID")
    .params(["id", Integer, "ID of the Agent Type"])
    .returns([200, "(:agent_type)"],
             [404, '{"error":"Agent Type not found"}']) \
  do
    AgentType.to_jsonmodel(AgentType.get_or_die(params[:id]),
                           :agent_type).to_json
  end


  Endpoint.get('/agent_types')
    .description("Get a list of Agent Types")
    .returns([200, "[(:agent_type)]"]) \
  do
    json_response(AgentType.collect {|at|
                    AgentType.to_jsonmodel(at, :agent_type).to_hash
                  })
  end

end
