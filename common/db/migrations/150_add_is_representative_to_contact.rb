require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:agent_contact) do
      add_column(:is_representative, Integer, :null => true, :default => nil)

      add_unique_constraint([:is_representative, :agent_person_id],
        :name => "agent_person_one_representative_contact")

      add_unique_constraint([:is_representative, :agent_corporate_entity_id],
        :name => "agent_corporate_entity_one_representative_contact")

      add_unique_constraint([:is_representative, :agent_family_id],
        :name => "agent_family_one_representative_contact")

      add_unique_constraint([:is_representative, :agent_software_id],
        :name => "agent_software_one_representative_contact")
    end
  end

  down do
  end

end
