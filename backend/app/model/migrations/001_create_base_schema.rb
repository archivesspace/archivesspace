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
      String :name, :null => false
      String :source, :null => false

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

    create_table(:resources) do
      primary_key :id

      Integer :repo_id, :null => false
      String :title, :null => false

      String :identifier, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:resources) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_index([:repo_id, :identifier], :unique => true)
    end


    create_table(:archival_objects) do
      primary_key :id

      Integer :repo_id, :null => false
      Integer :resource_id, :null => true

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
      add_foreign_key([:resource_id], :resources, :key => :id)
      add_foreign_key([:parent_id], :archival_objects, :key => :id)
      add_index([:resource_id, :ref_id], :unique => true)
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

    create_join_table(:subject_id => :subjects, :term_id => :terms)
    create_join_table(:subject_id => :subjects, :archival_object_id => :archival_objects)
    create_join_table(:subject_id => :subjects, :resource_id => :resources)

    create_table(:agent_types) do
      primary_key :id

      String :model_name, :null => false
      String :label, :null => false
    end

    self[:agent_types].insert(:model_name => "PersonName", :label => "Person")
    self[:agent_types].insert(:model_name => "FamilyName", :label => "Family")
    self[:agent_types].insert(:model_name => "CorporateEntityName", :label => "Corporate Entity")
    self[:agent_types].insert(:model_name => "SoftwareName", :label => "Software")

    create_table(:agents) do
      primary_key :id

      Integer :agent_type_id, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:agents) do
      add_foreign_key([:agent_type_id], :agent_types, :key => :id)
    end

    create_table(:name_forms) do
      primary_key :id

      Integer :agent_id, :null => false
      String :kind, :null => false

      String :sort_name, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:name_forms) do
      add_foreign_key([:agent_id], :agents, :key => :id)
    end

    create_table(:person_names) do
 #     primary_key :id

 #     Integer :name_form_id, :null => false
     Integer :id, :null => false

      String :primary_name, :null => false
    end

    alter_table(:person_names) do
 #     add_foreign_key([:name_form_id], :name_forms, :key => :id)
     add_foreign_key([:id], :name_forms, :key => :id)
    end

    create_table(:family_names) do
      primary_key :id

      Integer :name_form_id, :null => false

      String :family_name, :null => false
    end

    alter_table(:family_names) do
      add_foreign_key([:name_form_id], :name_forms, :key => :id)
    end

    create_table(:corporate_entity_names) do
      primary_key :id

      Integer :name_form_id, :null => false

      String :primary_name, :null => false
    end

    alter_table(:corporate_entity_names) do
      add_foreign_key([:name_form_id], :name_forms, :key => :id)
    end

    create_table(:software_names) do
      primary_key :id

      Integer :name_form_id, :null => false

      String :software_name, :null => false
    end

    alter_table(:software_names) do
      add_foreign_key([:name_form_id], :name_forms, :key => :id)
    end


  end

  down do

    [:subjects_terms, :archival_objects_subjects, :subjects, :terms,
     :person_names, :family_names, :corporate_entity_names, :software_names,
     :name_forms, :agents, :agent_types,
     :sessions, :auth_db, :groups_users, :users, :groups, :accessions,
     :archival_objects, :vocabularies,
     :resources, :repositories].each do |table|
      puts "Dropping #{table}"
      drop_table?(table)
    end

  end
end
