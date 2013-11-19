Sequel.migration do

  up do
    alter_table(:date) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      add_foreign_key([:name_person_id], :name_person, :key => :id)
      add_foreign_key([:name_family_id], :name_family, :key => :id)
      add_foreign_key([:name_corporate_entity_id], :name_corporate_entity, :key => :id)
      add_foreign_key([:name_software_id], :name_software, :key => :id)
    end
  end

  down do
    alter_table(:date) do
      drop_foreign_key(:agent_person_id)
      drop_foreign_key(:agent_family_id)
      drop_foreign_key(:agent_corporate_entity_id)
      drop_foreign_key(:agent_software_id)
      drop_foreign_key(:name_person_id)
      drop_foreign_key(:name_family_id)
      drop_foreign_key(:name_corporate_entity_id)
      drop_foreign_key(:name_software_id)
    end
  end

end
