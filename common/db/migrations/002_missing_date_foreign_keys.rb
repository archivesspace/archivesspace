Sequel.migration do

  up do
    alter_table(:date) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id, :name => 'agent_person_date_fk')
      add_foreign_key([:agent_family_id], :agent_family, :key => :id, :name => 'agent_family_date_fk')
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id, :name => 'agent_corporate_entity_date_fk')
      add_foreign_key([:agent_software_id], :agent_software, :key => :id, :name => 'agent_software_date_fk')
      add_foreign_key([:name_person_id], :name_person, :key => :id, :name => 'name_person_date_fk')
      add_foreign_key([:name_family_id], :name_family, :key => :id, :name => 'name_family_date_fk')
      add_foreign_key([:name_corporate_entity_id], :name_corporate_entity, :key => :id, :name => 'name_corporate_entity_date_fk')
      add_foreign_key([:name_software_id], :name_software, :key => :id, :name => 'name_software_date_fk')
    end
  end

  down do
    # Removed due to changes to foreign keys as part of ANW-429. You can't downgrade anyway.
  end

end
