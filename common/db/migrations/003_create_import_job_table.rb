require_relative 'utils'

Sequel.migration do

  up do

    create_table(:import_job) do
      primary_key :id

      String :import_type, :null => false
      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      MediumBlobField :filenames, :null => false

      DateTime :time_submitted, :null => false
      DateTime :time_started, :null => true
      DateTime :time_finished, :null => true

      Integer :owner_id, :null => false

      String :status, :null => false
  
      apply_mtime_columns
    end


    alter_table(:import_job) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:owner_id], :user, :key => :id)
    end


    create_table(:import_job_input_file) do
      primary_key :id

      Integer :job_id, :null => false
      String :file_path, :null => false
    end

    alter_table(:import_job_input_file) do
      add_foreign_key([:job_id], :import_job, :key => :id)
    end


    create_table(:import_job_created_record) do
      primary_key :id

      Integer :job_id, :null => false
      String :record_uri, :null => false

      apply_mtime_columns
    end

    alter_table(:import_job_created_record) do
      add_foreign_key([:job_id], :import_job, :key => :id)
    end


  end


  down do
    drop_table(:import_job_input_file)
    drop_table(:import_job_created_record)
    drop_table(:import_job)
  end

end

