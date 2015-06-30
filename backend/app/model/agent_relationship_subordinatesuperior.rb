class AgentRelationshipSubordinatesuperior < Sequel::Model(:agent_relationship_subordinatesuperior)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_subordinatesuperior)

end
