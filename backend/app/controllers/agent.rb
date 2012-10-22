class ArchivesSpaceService < Sinatra::Base

  @@agent_types = [[AgentPerson, :agent_person, NamePerson, :name_person],
                   [AgentFamily, :agent_family, NameFamily, :name_family],
                   [AgentCorporateEntity, :agent_corporate_entity, NameCorporateEntity, :name_corporate_entity],
                   [AgentSoftware, :agent_software, NameSoftware, :name_software]]

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
    json_response(@@agent_types.map {|agent_model, agent_type, name_model, name_type|
                    agent_model.where(name_type => name_model.
                                      where(Sequel.like(Sequel.function(:lower, :sort_name),
                                                        "#{params[:q]}%".downcase))).all.collect {
                      |agent|
                      agent_model.to_jsonmodel(agent, agent_type, :none).to_hash
                    }
                  }.flatten)
  end

end
