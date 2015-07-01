class AgentRelationshipParentchild < Sequel::Model(:agent_relationship_parentchild)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_parentchild)

end
