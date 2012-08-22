Sequel.migration do
  up do
    DB_TYPE = self.database_type

    create_table(:sessions) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false
      if DB_TYPE == :derby
        Clob :session_data, :null => true
      else
        Blob :session_data, :null => true
      end
    end


    create_table(:auth_db) do
      primary_key :id
      String :username, :unique => true, :null => false
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
      String :pwhash, :null => false
    end


    create_table(:users) do
      primary_key :id

      String :username, :null => false, :unique => true
      String :first_name, :null => false
      String :last_name, :null => false
      String :auth_source, :null => false
      String :email, :null => true
      String :phone, :null => true
      String :title, :null => true
      String :department, :null => true
      String :contact, :null => true
      String :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups) do
      primary_key :id

      String :group_id, :null => false, :unique => true
      String :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups_users) do
      primary_key :id

      Integer :user_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:groups_users) do
      add_foreign_key([:user_id], :users, :key => :id)
      add_foreign_key([:group_id], :groups, :key => :id)
    end


    create_table(:repositories) do
      primary_key :id

      String :repo_code, :null => false, :unique => true
      String :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:accessions) do
      primary_key :id

      Integer :repo_id, :null => false

      String :identifier, :null => false, :unique => true

      String :title, :null => true
      String :content_description, :null => true
      String :condition_description, :null => true

      DateTime :accession_date, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:accessions) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
    end

    create_table(:collections) do
      primary_key :id

      Integer :repo_id, :null => false
      String :title, :null => false

      String :identifier, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:collections) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_index([:repo_id, :identifier], :unique => true)
    end


    create_table(:archival_objects) do
      primary_key :id

      Integer :repo_id, :null => false
      Integer :collection_id, :null => true

      Integer :parent_id, :null => true

      String :ref_id, :null => false, :unique => false
      String :component_id, :null => true

      String :title, :null => true
      String :level, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:archival_objects) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_foreign_key([:collection_id], :collections, :key => :id)
      add_foreign_key([:parent_id], :archival_objects, :key => :id)
      add_index([:collection_id, :ref_id], :unique => true)
    end


    create_table(:vocabularies) do
      primary_key :id
      
      String :name, :null => false, :unique => true
      String :ref_id, :null => false, :unique => true
      
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    self[:vocabularies].insert(:name => "global", :ref_id => "global", 
      :create_time => Time.now, :last_modified => Time.now)


    create_table(:subjects) do
      primary_key :id

      Integer :vocab_id, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:subjects) do
      add_foreign_key([:vocab_id], :vocabularies, :key => :id)
    end

    create_table(:terms) do
      primary_key :id

      Integer :vocab_id, :null => false

      String :term, :null => false
      String :term_type, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false      
    end    

    alter_table(:terms) do
      add_foreign_key([:vocab_id], :vocabularies, :key => :id)
      add_index([:vocab_id, :term, :term_type], :unique => true)
    end

    create_join_table(:subject_id=>:subjects, :term_id=>:terms)
    create_join_table(:subject_id=>:subjects, :archival_object_id=>:archival_objects)


  end

  down do

    [:subjects_terms, :archival_objects_subjects, :subjects, :terms, :sessions,
     :auth_db, :groups_users, :users, :groups, :accessions,
     :archival_objects, :vocabularies,
     :collections, :repositories].each do |table|
      puts "Dropping #{table}"
      drop_table?(table)
    end

  end
end
