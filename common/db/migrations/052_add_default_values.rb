require_relative 'utils'

Sequel.migration do

  up do
    create_table(:default_values) do
      Integer :lock_version, :default => 0, :null => false
      String :id, :primary_key => true
      TextBlobField :blob, :null => false
      Integer :repo_id, :null => false
      String :record_type, :null => false

      apply_mtime_columns
    end
  end


  down do
    drop_table(:default_values)
  end

end
