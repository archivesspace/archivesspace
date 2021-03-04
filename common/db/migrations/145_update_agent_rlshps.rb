require_relative 'utils'

agent_relationships = %w[agent_relationship_associative_relator
                         agent_relationship_earlierlater_relator
                         agent_relationship_parentchild_relator
                         agent_relationship_subordinatesuperior_relator
                         agent_relationship_identity_relator
                         agent_relationship_hierarchical_relator
                         agent_relationship_temporal_relator
                         agent_relationship_family_relator]

existing_relators = %w[is_associative_with
                       is_earlier_form_of
                       is_later_form_of
                       is_parent_of
                       is_child_of
                       is_subordinate_to
                       is_superior_of
                       is_identified_with
                       is_hierarchical_with
                       is_temporal_with
                       is_related_with]

Sequel.migration do
  up do
    # Add new enum for specific relationship
    create_editable_enum('agent_relationship_specific_relator', [])

    # Add the new columns
    alter_table(:related_agents_rlshp) do
      add_column(:relator_id, Integer, :null => true)
      add_foreign_key([:relator_id], :enumeration_value, :key => :id)
      add_column(:specific_relator_id, Integer, :null => true)
      add_foreign_key([:specific_relator_id], :enumeration_value, :key => :id)
      add_column(:relationship_uri, String, :null => true)
      set_column_allow_null :relator
    end

    # Migrate enumeration values to relator_id from relator string
    agent_relationships.each do |rel|
      enum = self[:enumeration].filter(:name => rel).select(:id)
      enumeration_values = self[:enumeration_value].filter(:enumeration_id => enum).all

      self.transaction do
        enumeration_values.each do |value|
          self[:related_agents_rlshp].filter(:relator => value[:value],
                                             :relator_id => nil)
                                     .update(:relator => nil,
                                             :relator_id => value[:id])
        end
      end
    end

    alter_table(:related_agents_rlshp) do
      set_column_not_null(:relator_id)
    end

    # Attempt to delete old relator string
    if self[:related_agents_rlshp].filter(Sequel.~(:relator => nil)).count == 0
      alter_table(:related_agents_rlshp) do
        drop_column(:relator)
      end
    else
      $stderr.puts("WARNING: we tried to drop the column " +
                   "'related_agents_rlshp.relator' as a part of " +
                   "migration 145_update_agent_rlshps.rb but " +
                   "there's still data in it.  Please contact " +
                   "support as your migration may be incomplete.")
    end

    # These probably shouldn't have been editable in the first place since
    # the presence of 1 or 2 (and only 1 or 2) relators here conveys meaning
    # in directional relationships.
    existing_relators.each do |val|
      self[:enumeration_value].filter(:value => val).update(:readonly => 1)
    end

  end
end
