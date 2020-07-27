class AgentRelationshipFamily < Sequel::Model(:agent_relationship_family)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_family)

end
