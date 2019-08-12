require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Adding ARK name table")
    create_table(:ark_name) do
      primary_key :id

      Integer :archival_object_id, :index => true
      Integer :resource_id, :index => true
      String :created_by
      String :last_modified_by
      DateTime :create_time
      DateTime :system_mtime
      DateTime :user_mtime
      Integer :lock_version, :default => 0, :null => false
    end
  end

  down do
    $stderr.puts("Dropping ARK name table")
    drop_table(:ark_name)
  end
end
