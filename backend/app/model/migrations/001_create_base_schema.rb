Sequel.extension :inflector

Sequel.migration do
  up do
    create_table(:sessions) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false

      BlobField :session_data, :null => true
    end


    create_table(:auth_db) do
      primary_key :id
      String :username, :unique => true, :null => false
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
      String :pwhash, :null => false
    end


    create_table(:webhook_endpoints) do
      primary_key :id
      String :url, :unique => true, :null => false
    end


    create_table(:users) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :username, :null => false, :unique => true
      String :name, :null => false
      String :source, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:repositories) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :repo_code, :null => false, :unique => true
      String :description, :null => false

      Integer :hidden, :default => 0

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      String :group_code, :null => false
      TextField :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:groups) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_index([:repo_id, :group_code], :unique => true)
    end


    create_table(:groups_users) do
      primary_key :id

      Integer :user_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:groups_users) do
      add_foreign_key([:user_id], :users, :key => :id)
      add_foreign_key([:group_id], :groups, :key => :id)

      add_index(:group_id)
      add_index(:user_id)
    end


    create_table(:permissions) do
      primary_key :id

      String :permission_code, :unique => true
      TextField :description, :null => false
      String :level, :default => "repository"

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups_permissions) do
      primary_key :id

      Integer :permission_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:groups_permissions) do
      add_foreign_key([:permission_id], :permissions, :key => :id)
      add_foreign_key([:group_id], :groups, :key => :id)

      add_index(:permission_id)
      add_index(:group_id)

      add_index([:permission_id, :group_id], :unique => true)
    end


    create_table(:accessions) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      String :identifier, :null => false, :unique => true

      String :title, :null => true
      TextField :content_description, :null => true
      TextField :condition_description, :null => true

      DateTime :accession_date, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:accessions) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
    end

    create_table(:resources) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false
      String :title, :null => false

      String :identifier, :null => false

      Blob :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:resources) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_index([:repo_id, :identifier], :unique => true)
    end


    create_table(:instances) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :resource_id

      String :instance_type, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:instances) do
      add_foreign_key([:resource_id], :resources, :key => :id)
    end


    create_table(:containers) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :instance_id

      String :type_1, :null => false
      String :indicator_1, :null => false
      String :barcode_1

      String :type_2
      String :indicator_2

      String :type_3
      String :indicator_3

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:containers) do
      add_foreign_key([:instance_id], :instances, :key => :id)
    end


    create_table(:archival_objects) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false
      Integer :resource_id, :null => true

      Integer :parent_id, :null => true

      String :ref_id, :null => false, :unique => false
      String :component_id, :null => true

      TextField :title, :null => true
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

      Integer :lock_version, :default => 0, :null => false

      String :name, :null => false, :unique => true
      String :ref_id, :null => false, :unique => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    self[:vocabularies].insert(:name => "global", :ref_id => "global",
                               :create_time => Time.now, :last_modified => Time.now)


    create_table(:subjects) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :vocab_id, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:subjects) do
      add_foreign_key([:vocab_id], :vocabularies, :key => :id)
    end


    create_table(:terms) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

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
    create_join_table(:subject_id => :subjects, :accession_id => :accessions)


    create_table(:agent_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_family) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_corporate_entity) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:agent_software) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    class Sequel::Schema::CreateTableGenerator
      def apply_name_columns
        String :authority_id, :null => true
        String :dates, :null => true
        TextField :description_type, :null => true
        TextField :description_note, :null => true
        TextField :description_citation, :null => true
        TextField :qualifier, :null => true
        String :source, :null => true
        String :rules, :null => true
        TextField :sort_name, :null => true
      end
    end

    create_table(:name_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_person_id, :null => false

      String :primary_name, :null => false
      String :direct_order, :null => false

      TextField :title, :null => true
      TextField :prefix, :null => true
      TextField :rest_of_name, :null => true
      TextField :suffix, :null => true
      TextField :fuller_form, :null => true
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

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_family_id, :null => false

      TextField :family_name, :null => false

      TextField :prefix, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_family) do
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
    end


    create_table(:name_corporate_entity) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_corporate_entity_id, :null => false

      TextField :primary_name, :null => false

      TextField :subordinate_name_1, :null => true
      TextField :subordinate_name_2, :null => true
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

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_software_id, :null => false

      TextField :software_name, :null => false

      TextField :version, :null => true
      TextField :manufacturer, :null => true

      apply_name_columns

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:name_software) do
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:agent_contacts) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      TextField :name, :null => false
      TextField :salutation, :null => true
      TextField :address_1, :null => true
      TextField :address_2, :null => true
      TextField :address_3, :null => true
      TextField :city, :null => true
      TextField :region, :null => true
      TextField :country, :null => true
      TextField :post_code, :null => true
      TextField :telephone, :null => true
      TextField :telephone_ext, :null => true
      TextField :fax, :null => true
      TextField :email, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:agent_contacts) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:extents) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true

      String :portion, :null => false
      String :number, :null => false
      String :extent_type, :null => false

      String :container_summary, :null => true
      String :physical_details, :null => true
      String :dimensions, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:extents) do
      add_foreign_key([:accession_id], :accessions, :key => :id)
      add_foreign_key([:archival_object_id], :archival_objects, :key => :id)
      add_foreign_key([:resource_id], :resources, :key => :id)
    end


    create_table(:dates) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true

      String :date_type, :null => false
      String :label, :null => false

      String :uncertain, :null => true
      String :expression, :null => true
      String :begin, :null => true
      String :begin_time, :null => true
      String :end, :null => true
      String :end_time, :null => true
      String :era, :null => true
      String :calendar, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:dates) do
      add_foreign_key([:accession_id], :accessions, :key => :id)
      add_foreign_key([:archival_object_id], :archival_objects, :key => :id)
      add_foreign_key([:resource_id], :resources, :key => :id)
    end


    create_table(:rights_statements) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true

      Integer :repo_id, :null => false

      String :identifier, :null => false
      String :rights_type, :null => false

      Integer :active

      String :materials, :null => true

      String :ip_status, :null => true
      DateTime :ip_expiration_date, :null => true

      String :license_identifier_terms, :null => true
      String :statute_citation, :null => true

      String :jurisdiction, :null => true
      String :type_note, :null => true

      String :permissions, :null => true
      String :restrictions, :null => true
      DateTime :restriction_start_date, :null => true
      DateTime :restriction_end_date, :null => true

      String :granted_note, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:rights_statements) do
      add_foreign_key([:accession_id], :accessions, :key => :id)
      add_foreign_key([:archival_object_id], :archival_objects, :key => :id)
      add_foreign_key([:resource_id], :resources, :key => :id)

      add_foreign_key([:repo_id], :repositories, :key => :id)
      add_index([:repo_id, :identifier], :unique => true)
    end


    create_table(:external_documents) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :title, :null => false
      String :location, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    records_supporting_external_documents = [:accession, :archival_object,
                                             :resource, :subject,
                                             :agent_person,
                                             :agent_family,
                                             :agent_corporate_entity,
                                             :agent_software,
                                             :rights_statement]

    records_supporting_external_documents.each do |record|
      table = table_exists?(record) ? record : record.to_s.pluralize.intern

      create_join_table({
                          "#{record}_id".intern => table,
                          :external_document_id => :external_documents
                        },
                        :name => "#{table}_external_documents",
                        :index_options => {:name => "ed_#{record}_idx"})
    end


    create_table(:locations) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      String :building, :null => false

      String :floor
      String :room
      String :area
      String :barcode
      String :classification
      String :coordinate_1_label
      String :coordinate_1_indicator
      String :coordinate_2_label
      String :coordinate_2_indicator
      String :coordinate_3_label
      String :coordinate_3_indicator
      String :temporary

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:locations) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
    end

    create_table(:container_locations) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :location_id
      Integer :container_id

      String :status
      String :start_date
      String :end_date
      String :note

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:container_locations) do
      add_foreign_key([:location_id], :locations, :key => :id)
      add_foreign_key([:container_id], :containers, :key => :id)
    end

  end

  down do

    [:external_documents, :rights_statements, :location, :container_locations,
     :subjects_terms, :archival_objects_subjects, :resources_subjects, :accessions_subjects, :subjects, :terms,
     :agent_contacts, :name_person, :name_family, :agent_person, :agent_family,
     :name_corporate_entity, :name_software, :agent_corporate_entity, :agent_software,
     :sessions, :auth_db, :groups_users, :groups_permissions, :permissions, :users, :groups, :accessions,
     :dates, :archival_objects, :vocabularies, :extents, :resources, :repositories,
     :accessions_external_documents, :archival_objects_external_documents,
     :external_documents_resources, :external_documents_subjects,
     :agent_people_external_documents, :agent_families_external_documents,
     :agent_corporate_entities_external_documents,
     :agent_softwares_external_documents].each do |table|
      puts "Dropping #{table}"
      drop_table?(table)
    end

  end
end
