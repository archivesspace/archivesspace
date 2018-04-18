require_relative 'utils'

Sequel.migration do
  up do
    create_table(:ark_identifier) do
      primary_key :id

      Integer :resource_id
      Integer :accession_id
      Integer :digital_object_id
      Integer :resource_type_id,  :null => false
      Integer :repo_id,           :null => false
    end

    alter_table(:ark_identifier) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:resource_type_id], :enumeration_value, :key => :id)
      add_foreign_key([:repo_id], :repository, :key => :id)
    end
  end

  down do
    alter_table(:ark_identifier) do
      drop_foreign_key([:resource_id])
      drop_foreign_key([:accession_id])
      drop_foreign_key([:digital_object_id])
      drop_foreign_key([:resource_type_id])
      drop_foreign_key([:repo_id])
    end 

    drop_table(:ark_identifier)
  end
end
