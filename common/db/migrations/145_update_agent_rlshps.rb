require_relative 'utils'

agent_relationships = %w[agent_relationship_associative_relator
                         agent_relationship_earlierlater_relator agent_relationship_parentchild_relator agent_relationship_subordinatesuperior_relator
                         agent_relationship_identity_relator
                         agent_relationship_hierarchical_relator
                         agent_relationship_temporal_relator
                         agent_relationship_family_relator]

Sequel.migration do
  up do
    $stderr.puts 'Updating agent relationship relator lists to be editable'
    agent_relationships.each do |rel|
      self[:enumeration].filter(:name => rel).update(:editable => 1)
    end
  end
end
