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
    foreign_keys = ['agent_person_date_fk',
                    'agent_family_date_fk',
                    'agent_corporate_entity_date_fk',
                    'agent_software_date_fk',
                    'name_person_date_fk',
                    'name_family_date_fk',
                    'name_corporate_entity_date_fk',
                    'name_software_date_fk']


    foreign_keys.each do |fk|
      alter_table(:date) do
        drop_constraint(fk)
      end

      if $db_type == :mysql
        self.run("alter table date drop foreign key #{fk}")
      end
    end
  end

end

