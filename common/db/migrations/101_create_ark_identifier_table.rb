require_relative 'utils'

Sequel.migration do
  up do
    create_table(:ark_identifier) do
      primary_key :id

      Integer :resource_id
      Integer :accession_id
      Integer :digital_object_id
    end

    alter_table(:ark_identifier) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end
  end

  down do
    alter_table(:ark_identifier) do
      drop_foreign_key([:resource_id])
      drop_foreign_key([:accession_id])
      drop_foreign_key([:digital_object_id])
    end 

    drop_table(:ark_identifier)
  end
end
