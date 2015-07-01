class AgentRelationshipEarlierlater < Sequel::Model(:agent_relationship_earlierlater)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_earlierlater)

end
