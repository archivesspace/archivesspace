class AgentRelationshipAssociative < Sequel::Model(:related_agents_rlshp)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_associative)

end
