class AgentRelationshipTemporal < Sequel::Model(:agent_relationship_temporal)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_temporal)

end
