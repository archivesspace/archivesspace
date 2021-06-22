class AgentRelationshipFamily < Sequel::Model(:related_agents_rlshp)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_family)

end
