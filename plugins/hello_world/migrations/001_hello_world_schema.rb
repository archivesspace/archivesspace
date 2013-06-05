Sequel.migration do
  up do

    create_table(:whosaidhello) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true

      String :who, :null => false

      apply_mtime_columns
    end


    alter_table(:whosaidhello) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end

  end

  down do
    drop_table(:whosaidhello)
  end

end
