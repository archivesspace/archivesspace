require_relative 'utils'

Sequel.migration do

  up do
    create_table(:find_and_replace_job) do
      primary_key :id

      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      MediumBlobField :arguments, :null => false
      MediumBlobField :scope, :null => false

      DateTime :time_submitted, :null => false
      DateTime :time_started, :null => true
      DateTime :time_finished, :null => true

      Integer :owner_id, :null => false

      String :status, :null => false
  
      apply_mtime_columns
    end

    alter_table(:find_and_replace_job) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:owner_id], :user, :key => :id)
    end
  end

  down do
    drop_table(:find_and_replace_job)
  end
end

