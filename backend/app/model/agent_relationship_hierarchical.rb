class AgentRelationshipHierarchical < Sequel::Model(:agent_relationship_hierarchical)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_hierarchical)

end
