require_relative 'utils'

Sequel.migration do

  up do
    create_table(:required_fields) do
      Integer :lock_version, :default => 0, :null => false
      String :id, :primary_key => true
      TextBlobField :blob, :null => false
      Integer :repo_id, :null => false
      String :record_type, :null => false

      apply_mtime_columns
    end
  end


  down do
    drop_table(:required_fields)
  end

end
