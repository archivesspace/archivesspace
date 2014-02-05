require_relative 'utils'

Sequel.migration do

  up do
    [:resource, :archival_object, :digital_object, :digital_object_component].each do |table|
      alter_table(table) do
        add_column(:suppressed, :integer, :null => false, :default => 0)
      end
    end


    [:classification_creator_rlshp, :classification_rlshp,
     :classification_term_creator_rlshp, :event_link_rlshp, :housed_at_rlshp,
     :instance_do_link_rlshp, :linked_agents_rlshp, :related_agents_rlshp,
     :spawned_rlshp, :subject_rlshp].each do |relationship_table|

      alter_table(relationship_table) do
        add_column(:suppressed, :integer, :null => false, :default => 0)
      end
    end

  end


  down do
  end

end

