class AgentRelationshipAssociative < Sequel::Model(:agent_relationship_associative)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_associative)

end
