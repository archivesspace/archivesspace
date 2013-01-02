class ArchivesSpaceService < Sinatra::Base

  # FIXME: needs pagination
  # We'll likely get rid of this soon in favour of running browses from the Solr indexes.
  Endpoint.get('/agents')
    .description("Get all agent records")
    .returns([200, "[(:agent)]"]) \
  do
    agents = AgentManager.type_to_model_map.map {|type, model|
      model.all.collect {|agent| model.to_jsonmodel(agent).to_hash}
    }

    json_response(agents.flatten)
  end
end
