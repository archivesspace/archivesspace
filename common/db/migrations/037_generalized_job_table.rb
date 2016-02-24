require_relative 'utils'

Sequel.migration do

  up do
    create_enum("job_type", ["import_job", "find_and_replace_job"])

    create_table(:job) do
      primary_key :id

      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      DynamicEnum :job_type_id, :null => false
      MediumBlobField :job_blob, :null => false

      DateTime :time_submitted, :null => false
      DateTime :time_started, :null => true
      DateTime :time_finished, :null => true

      Integer :owner_id, :null => false

      String :status, :null => false

      apply_mtime_columns
    end

    alter_table(:job) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:owner_id], :user, :key => :id)
    end


    # move legacy jobs over
    self[:import_job].all.each do |row|

      job_type_id = self[:enumeration_value].filter(:value => 'import_job').first[:id]

      self[:job].insert(:repo_id => row[:repo_id],
                        :lock_version => row[:lock_version],
                        :json_schema_version => row[:json_schema_version],
                        :job_type_id => job_type_id,
                        :job_blob => blobify(self, ASUtils.to_json({:import_type => row[:import_type], :filenames => ASUtils.json_parse(row[:filenames])})),
                        :owner_id => row[:owner_id],
                        :status => row[:status],
                        :time_submitted => row[:time_submitted],
                        :time_started => row[:time_started],
                        :time_finished => row[:time_finished],
                        :created_by => row[:created_by],
                        :last_modified_by => row[:last_modified_by],
                        :create_time => row[:create_time],
                        :system_mtime => row[:system_mtime],
                        :user_mtime => row[:user_mtime])

    end


    # import_job_input_file --> job_input_file
    create_table(:job_input_file) do
      primary_key :id

      Integer :job_id, :null => false
      String :file_path, :null => false

    end

    alter_table(:job_input_file) do
      add_foreign_key([:job_id], :job, :key => :id)
    end

    self[:import_job_input_file].all.each do |row|

      self[:job_input_file].insert(:file_path => row[:file_path],
                                   :job_id => row[:job_id]
                                   )
    end

    drop_table(:import_job_input_file)


    # import_job_created_record --> job_created_record
    create_table(:job_created_record) do
      primary_key :id

      Integer :job_id, :null => false
      String :record_uri, :null => false

      apply_mtime_columns
    end

    alter_table(:job_created_record) do
      add_foreign_key([:job_id], :job, :key => :id)
    end

    self[:import_job_created_record].all.each do |row|

      self[:job_created_record].insert(:record_uri => row[:record_uri],
                                       :job_id => row[:job_id],
                                       :created_by => row[:created_by],
                                       :last_modified_by => row[:last_modified_by],
                                       :create_time => row[:create_time],
                                       :system_mtime => row[:system_mtime],
                                       :user_mtime => row[:user_mtime]
                                       )
    end

    drop_table(:import_job_created_record)


    # new modified record table
    create_table(:job_modified_record) do
      primary_key :id

      Integer :job_id, :null => false
      String :record_uri, :null => false

      apply_mtime_columns
    end

    alter_table(:job_modified_record) do
      add_foreign_key([:job_id], :job, :key => :id)
    end

    drop_table(:import_job)

  end


  down do
    # sorry there's no going back
    # but we do need to recreate the table structure
    # for db:nuke to work
    drop_table(:job_input_file) 
    drop_table(:job_created_record)  
    drop_table(:job_modified_record) 
    drop_table(:job)
    
    # taken from migration 003
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
end
