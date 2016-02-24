require_relative 'utils'

Sequel.migration do

  up do

    alter_table(:rights_statement) do
      add_column( :agent_person_id, :integer,  :null => true ) 
      add_column( :agent_family_id, :integer,  :null => true ) 
      add_column( :agent_corporate_entity_id, :integer,  :null => true ) 
      add_column( :agent_software_id, :integer,  :null => true ) 
      add_foreign_key([:agent_person_id], :agent_person, :key => :id, :name => 'agent_person_rights_statement_fk')
      add_foreign_key([:agent_family_id], :agent_family, :key => :id, :name => 'agent_family_rights_statement_fk')
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id, :name => 'agent_corporate_entity_rights_statement_fk')
      add_foreign_key([:agent_software_id], :agent_software, :key => :id, :name => 'agent_software_rights_statement_fk')
      
      drop_foreign_key [:repo_id]
      drop_constraint( :rights_unique_identifier, :type => :unique )
      set_column_allow_null :repo_id
    end

  end

  down do
  end

end
