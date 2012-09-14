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


    create_table(:agent_person) do
      primary_key :id

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_family) do
      primary_key :id

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_corporate_entity) do
      primary_key :id

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_software) do
      primary_key :id

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    class Sequel::Schema::CreateTableGenerator
      def apply_name_columns
        String :authority_id, :null => false
        String :dates, :null => true
        String :description_type, :null => true
        String :description_note, :null => true
        String :description_citation, :null => true
        String :qualifier, :null => true
        String :source, :null => true
        String :rules, :null => true
        String :sort_name, :null => true
      end
    end

    create_table(:name_person) do
      primary_key :id

      Integer :agent_person_id, :null => false

      String :primary_name, :null => false
      String :direct_order, :null => false

      String :title, :null => true
      String :prefix, :null => true
      String :rest_of_name, :null => true
      String :suffix, :null => true
      String :fuller_form, :null => true
      String :number, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_person) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end


    create_table(:name_family) do
      primary_key :id

      Integer :agent_family_id, :null => false

      String :family_name, :null => false

      String :prefix, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_family) do
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
    end


    create_table(:name_corporate_entity) do
      primary_key :id

      Integer :agent_corporate_entity_id, :null => false

      String :primary_name, :null => false

      String :subordinate_name_1, :null => true
      String :subordinate_name_2, :null => true
      String :number, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_corporate_entity) do
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
    end


    create_table(:name_software) do
      primary_key :id

      Integer :agent_software_id, :null => false

      String :software_name, :null => false

      String :version, :null => true
      String :manufacturer, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_software) do
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:agent_contacts) do
      primary_key :id

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      String :name, :null => false
      String :salutation, :null => true
      String :address_1, :null => true
      String :address_2, :null => true
      String :address_3, :null => true
      String :city, :null => true
      String :region, :null => true
      String :country, :null => true
      String :post_code, :null => true
      String :telephone, :null => true
      String :telephone_ext, :null => true
      String :fax, :null => true
      String :email, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:agent_contacts) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


  end

  down do

    [:subjects_terms, :archival_objects_subjects, :subjects, :terms,
     :agent_contacts, :name_person, :name_family, :agent_person, :agent_family,
     :name_corporate_entity, :name_software, :agent_corporate_entity, :agent_software,
     :sessions, :auth_db, :groups_users, :users, :groups, :accessions,
     :archival_objects, :vocabularies,
     :resources, :repositories].each do |table|
      puts "Dropping #{table}"
      drop_table?(table)
    end

  end
end
