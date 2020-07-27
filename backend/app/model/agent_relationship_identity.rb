class AgentRelationshipIdentity < Sequel::Model(:agent_relationship_identity)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_identity)

end
