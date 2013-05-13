Sequel.extension :inflector

module MigrationUtils
  def self.shorten_table(name)
    name.to_s.split("_").map {|s| s[0...3]}.join("_")
  end 
end


Sequel.migration do
  up do

    create_table(:session) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false, :index => true
      Integer :expirable, :default => 1

      TextBlobField :session_data, :null => true
    end


    create_table(:enumeration) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :name, :null => false, :unique => true
      
      Integer :default_value

      Integer :editable, :default => 1

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:enumeration_value) do
      primary_key :id

      Integer :enumeration_id, :null => false, :index => true
      String :value, :null => false, :index => true
    end
 

    alter_table(:enumeration_value) do
      add_foreign_key([:enumeration_id], :enumeration, :key => :id)
      add_unique_constraint([:enumeration_id, :value], :name => "enumeration_value_uniq")
    end



    create_table(:auth_db) do
      primary_key :id
      String :username, :unique => true, :null => false
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
      String :pwhash, :null => false
    end


    create_table(:notification) do
      primary_key :id
      DateTime :time, :null => false, :index => true
      String :code, :null => false
      BlobField :params, :null => false
    end


    create_table(:agent_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:agent_family) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:agent_corporate_entity) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:agent_software) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:user) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :username, :null => false, :unique => true
      String :name, :null => false
      String :source, :null => true
      Integer :agent_record_id, :null => false
      String :agent_record_type, :null => false

      Integer :is_system_user, :default => 0, :null => false

      String :email
      String :first_name
      String :last_name
      String :telephone
      String :title
      String :department
      TextField :additional_contact

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:user) do
      add_foreign_key([:agent_record_id], :agent_person, :key => :id)
    end

    create_table(:repository) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :repo_code, :null => false, :unique => true
      String :name, :null => false
      String :org_code
      String :parent_institution_name
      String :url
      String :image_url
      TextField :contact_persons
      DynamicEnum :country_id

      Integer :agent_representation_id, :null => true

      Integer :hidden, :default => 0

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:repository) do
      add_foreign_key([:agent_representation_id], :agent_corporate_entity, :key => :id)
    end


    create_table(:group) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      String :group_code, :null => false
      String :group_code_norm, :null => false
      TextField :description, :null => false

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:group) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_unique_constraint([:repo_id, :group_code_norm], :name => "group_uniq")
    end


    create_table(:group_user) do
      primary_key :id

      Integer :user_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:group_user) do
      add_foreign_key([:user_id], :user, :key => :id)
      add_foreign_key([:group_id], :group, :key => :id)

      add_index(:group_id)
      add_index(:user_id)
    end


    create_table(:permission) do
      primary_key :id

      String :permission_code, :unique => true
      TextField :description, :null => false
      String :level, :default => "repository"

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:group_permission) do
      primary_key :id

      Integer :permission_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:group_permission) do
      add_foreign_key([:permission_id], :permission, :key => :id)
      add_foreign_key([:group_id], :group, :key => :id)

      add_index(:permission_id)
      add_index(:group_id)

      add_index([:permission_id, :group_id], :unique => true)
    end


    create_table(:accession) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      Integer :suppressed, :default => 0, :null => false

      String :identifier, :null => false

      LongString :title, :null => true
      
      Integer :publish
      
      TextField :content_description, :null => true
      TextField :condition_description, :null => true
      
      TextField :disposition
      TextField :inventory

      TextField :provenance
      
      TextField :general_note

      DynamicEnum :resource_type_id
      DynamicEnum :acquisition_type_id

      DateTime :accession_date, :null => true

      Integer :restrictions_apply
      
      TextField :retention_rule, :null => true
      
      Integer :access_restrictions
      TextField :access_restrictions_note
      
      Integer :use_restrictions
      TextField :use_restrictions_note

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:accession) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_unique_constraint([:repo_id, :identifier], :name => "accession_unique_identifier")
      add_index(:suppressed)
    end

    create_table(:resource) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      Integer :accession_id, :null => true
      LongString :title, :null => false

      String :identifier

      DynamicEnum :language_id, :null => false

      DynamicEnum :level_id, :null => false
      String :other_level

      DynamicEnum :resource_type_id, :null => true

      Integer :publish
      Integer :restrictions

      TextField :repository_processing_note
      TextField :container_summary

      String :ead_id
      String :ead_location

      TextField :finding_aid_title
      TextField :finding_aid_filing_title
      String :finding_aid_date
      String :finding_aid_author
      DynamicEnum :finding_aid_description_rules_id
      String :finding_aid_language
      String :finding_aid_sponsor
      TextField :finding_aid_edition_statement
      TextField :finding_aid_series_statement
      String :finding_aid_revision_date
      TextField :finding_aid_revision_description
      DynamicEnum :finding_aid_status_id
      TextField :finding_aid_note

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:resource) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_unique_constraint([:repo_id, :identifier], :name => "resource_unique_identifier")
      add_unique_constraint([:repo_id, :ead_id], :name => "resource_unique_ead_id")
    end


    create_table(:archival_object) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      Integer :root_record_id, :null => true
      Integer :parent_id, :null => true
      String :parent_name, :null => true
      Integer :position, :null => true
      
      Integer :publish

      String :ref_id, :null => false, :unique => false
      String :component_id, :null => true

      HalfLongString :title, :null => true
      HalfLongString :label, :null => true

      DynamicEnum :level_id, :null => false
      String :other_level

      DynamicEnum :language_id, :null => true

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:archival_object) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:root_record_id], :resource, :key => :id)
      add_foreign_key([:parent_id], :archival_object, :key => :id)

      add_unique_constraint([:root_record_id, :ref_id], :name => "ao_unique_refid")
      add_unique_constraint([:root_record_id, :parent_name, :position], :name => "ao_unique_position")
    end





    create_table(:digital_object) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      String :digital_object_id, :null => false
      LongString :title
      DynamicEnum :level_id
      DynamicEnum :digital_object_type_id
      DynamicEnum :language_id

      Integer :publish
      Integer :restrictions

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:digital_object) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_index([:repo_id, :digital_object_id], :unique => true)
    end


    create_table(:digital_object_component) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      Integer :root_record_id, :null => true
      Integer :parent_id, :null => true
      Integer :position, :null => true
      String :parent_name, :null => true

      Integer :publish

      String :component_id, :null => false
      LongString :title
      String :label
      DynamicEnum :language_id

      Integer :notes_json_schema_version, :null => false
      BlobField :notes, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:digital_object_component) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_index([:repo_id, :component_id], :unique => true)
      add_foreign_key([:root_record_id], :digital_object, :key => :id)
      add_foreign_key([:parent_id], :digital_object_component, :key => :id)

      add_unique_constraint([:root_record_id, :parent_name, :position], :name => "do_unique_position")
    end



    create_table(:instance) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :resource_id
      Integer :archival_object_id
      Integer :accession_id

      DynamicEnum :instance_type_id, :null => false

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:instance) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
    end

    create_table(:instance_do_link_rlshp) do
      primary_key :id
      Integer :digital_object_id
      Integer :instance_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:instance_do_link_rlshp) do
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:instance_id], :instance, :key => :id)
    end


    create_table(:container) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :instance_id

      DynamicEnum :type_1_id, :null => false
      String :indicator_1, :null => false
      String :barcode_1

      DynamicEnum :type_2_id
      String :indicator_2

      DynamicEnum :type_3_id
      String :indicator_3

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:container) do
      add_foreign_key([:instance_id], :instance, :key => :id)
    end


    create_table(:vocabulary) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :name, :null => false, :unique => true
      String :ref_id, :null => false, :unique => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    self[:vocabulary].insert(:name => "global", :ref_id => "global",
                             :create_time => Time.now, :last_modified => Time.now)


    create_table(:subject) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :vocab_id, :null => false

      LongString :title
      String :terms_sha1, :index => true, :null => false
      String :authority_id
      TextField :scope_note

      DynamicEnum :source_id, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:subject) do
      add_foreign_key([:vocab_id], :vocabulary, :key => :id)
      add_unique_constraint([:vocab_id, :authority_id, :source_id], :name => "subj_auth_source_uniq")
      add_unique_constraint([:vocab_id, :terms_sha1, :source_id], :name => "subj_terms_uniq")
    end


    create_table(:term) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :vocab_id, :null => false

      String :term, :null => false
      DynamicEnum :term_type_id, :null => false

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:term) do
      add_foreign_key([:vocab_id], :vocabulary, :key => :id)
      add_index([:vocab_id, :term, :term_type_id], :unique => true)
    end


    create_table(:subject_term) do
        primary_key :id

        Integer :subject_id, :null => false
        Integer :term_id, :null => false
      end

    alter_table(:subject_term) do
      add_foreign_key([:subject_id], :subject, :key => :id)
      add_foreign_key([:term_id], :term, :key => :id)
      add_index([:subject_id, :term_id], :name => "subject_term_idx")
    end


    class Sequel::Schema::CreateTableGenerator
      def apply_name_columns
        String :authority_id, :null => true
        String :dates, :null => true
        TextField :qualifier, :null => true
        DynamicEnum :source_id, :null => true
        DynamicEnum :rules_id, :null => true
        TextField :sort_name, :null => false
        Integer :sort_name_auto_generate
      end

    end


    def create_editable_enum(name, values, default = nil)
      create_enum(name, values, default, true)
    end


    def create_enum(name, values, default = nil, editable = false)
      id = self[:enumeration].insert(:name => name,
                                     :json_schema_version => 1,
                                     :editable => editable ? 1 : 0,
                                     :create_time => Time.now,
                                     :last_modified => Time.now)

      id_of_default = nil

      values.each do |value|
        id_of_value = self[:enumeration_value].insert(:enumeration_id => id, :value => value)
        id_of_default = id_of_value if value === default
      end

      if !id_of_default.nil?
        self[:enumeration].where(:id => id).update(:default_value => id_of_default)
      end
    end


    create_table(:name_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_person_id, :null => false

      String :primary_name, :null => false
      DynamicEnum :name_order_id, :null => false

      LongString :title, :null => true
      TextField :prefix, :null => true
      TextField :rest_of_name, :null => true
      TextField :suffix, :null => true
      TextField :fuller_form, :null => true
      String :number, :null => true

      apply_name_columns

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:name_person) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end


    create_table(:name_family) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_family_id, :null => false

      TextField :family_name, :null => false

      TextField :prefix, :null => true

      apply_name_columns

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:name_family) do
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
    end


    create_table(:name_corporate_entity) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_corporate_entity_id, :null => false

      TextField :primary_name, :null => false

      TextField :subordinate_name_1, :null => true
      TextField :subordinate_name_2, :null => true
      String :number, :null => true

      apply_name_columns

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:name_corporate_entity) do
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
    end


    create_table(:name_software) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_software_id, :null => false

      TextField :software_name, :null => false

      TextField :version, :null => true
      TextField :manufacturer, :null => true

      apply_name_columns

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:name_software) do
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:agent_contact) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      TextField :name, :null => false
      DynamicEnum :salutation_id, :null => true
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
      TextField :email_signature, :null => true
      TextField :note, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:agent_contact) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:deaccession) do
      primary_key :id

      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true

      DynamicEnum :scope_id, :null => false
      String :description, :null => false

      String :reason
      String :disposition

      Integer :notification

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:deaccession) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end


    create_table(:extent) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true
      Integer :deaccession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true


      Integer :portion_id, :null => false
      String :number, :null => false
      DynamicEnum :extent_type_id, :null => false

      TextField :container_summary, :null => true
      TextField :physical_details, :null => true
      String :dimensions, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:extent) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:deaccession_id], :deaccession, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end


    create_table(:related_agents_rlshp) do
      primary_key :id

      Integer :agent_person_id_0
      Integer :agent_person_id_1
      Integer :agent_corporate_entity_id_0
      Integer :agent_corporate_entity_id_1
      Integer :agent_software_id_0
      Integer :agent_software_id_1
      Integer :agent_family_id_0
      Integer :agent_family_id_1

      String :relator, :null => false
      String :relationship_target, :null => false
      String :jsonmodel_type, :null => false
      TextField :description, :null => true

      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:related_agents_rlshp) do
      add_foreign_key([:agent_person_id_0], :agent_person, :key => :id)
      add_foreign_key([:agent_person_id_1], :agent_person, :key => :id)
      add_foreign_key([:agent_corporate_entity_id_0], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_corporate_entity_id_1], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id_0], :agent_software, :key => :id)
      add_foreign_key([:agent_software_id_1], :agent_software, :key => :id)
      add_foreign_key([:agent_family_id_0], :agent_family, :key => :id)
      add_foreign_key([:agent_family_id_1], :agent_family, :key => :id)
    end


    create_table(:date) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true
      Integer :deaccession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :event_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true
      Integer :related_agents_rlshp_id, :null => true

      DynamicEnum :date_type_id, :null => true
      DynamicEnum :label_id, :null => false

      DynamicEnum :certainty_id, :null => true
      String :expression, :null => true
      String :begin, :null => true
      String :end, :null => true
      DynamicEnum :era_id, :null => true
      DynamicEnum :calendar_id, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    create_table(:event) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false
      Integer :suppressed, :default => 0, :null => false

      Integer :repo_id, :null => false

      DynamicEnum :event_type_id, :null => false
      DynamicEnum :outcome_id, :null => true
      String :outcome_note, :null => true

      DateTime :timestamp, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:event) do
      add_index(:suppressed)
      add_foreign_key([:repo_id], :repository, :key => :id)
    end


    alter_table(:date) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:event_id], :event, :key => :id)
      add_foreign_key([:deaccession_id], :deaccession, :key => :id)
      add_foreign_key([:related_agents_rlshp_id], :related_agents_rlshp, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)

    end


    create_table(:rights_statement) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

      Integer :repo_id, :null => false

      String :identifier, :null => false
      DynamicEnum :rights_type_id, :null => false

      Integer :active

      String :materials, :null => true

      DynamicEnum :ip_status_id, :null => true
      DateTime :ip_expiration_date, :null => true

      String :license_identifier_terms, :null => true
      String :statute_citation, :null => true

      DynamicEnum :jurisdiction_id, :null => true
      String :type_note, :null => true

      TextField :permissions, :null => true
      TextField :restrictions, :null => true
      DateTime :restriction_start_date, :null => true
      DateTime :restriction_end_date, :null => true

      String :granted_note, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    alter_table(:rights_statement) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)

      add_foreign_key([:repo_id], :repository, :key => :id)
      add_unique_constraint([:repo_id, :identifier], :name => "rights_unique_identifier")
    end


    create_table(:external_document) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      LongString :title, :null => false
      String :location, :null => false

      Integer :publish

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end


    records_supporting_external_documents = [:accession, :archival_object,
                                             :resource, :subject,
                                             :agent_person,
                                             :agent_family,
                                             :agent_corporate_entity,
                                             :agent_software,
                                             :rights_statement,
                                             :digital_object,
                                             :digital_object_component]

    records_supporting_external_documents.each do |record|
      table = "#{record}_external_document".intern

      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern
        Integer :external_document_id
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
        add_foreign_key([:external_document_id], :external_document, :key => :id)
      end
    end


    create_table(:location) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      String :building, :null => false

      LongString :title

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
      DynamicEnum :temporary_id

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:location) do
      add_foreign_key([:repo_id], :repository, :key => :id)
    end


    create_table(:collection_management) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true

      TextField :cataloged_note, :null => true
      String :processing_hours_per_foot_estimate, :null => true
      String :processing_total_extent, :null => true
      DynamicEnum :processing_total_extent_type_id, :null => true
      String :processing_hours_total, :null => true
      TextField :processing_plan, :null => true
      DynamicEnum :processing_priority_id, :null => true
      DynamicEnum :processing_status_id, :null => true
      TextField :processing_funding_source, :null => true
      TextField :processors, :null => true
      Integer :rights_determined, :default => 0, :null => false

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:collection_management) do
      add_foreign_key([:repo_id], :repository, :key => :id)

      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end


    create_table(:user_defined) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true

      Integer :boolean_1
      Integer :boolean_2

      String :integer_1, :null => true
      String :integer_2, :null => true

      String :real_1, :null => true
      String :real_2, :null => true

      String :string_1, :null => true
      String :string_2, :null => true
      String :string_3, :null => true

      TextField :text_1, :null => true
      TextField :text_2, :null => true
      TextField :text_3, :null => true
      TextField :text_4, :null => true

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:collection_management) do
      add_foreign_key([:repo_id], :repository, :key => :id)
    end


    create_table(:file_version) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

      DynamicEnum :use_statement_id, :null => true
      DynamicEnum :checksum_method_id, :null => true

      String :file_uri, :null => false
      Integer :publish
      DynamicEnum :xlink_actuate_attribute_id
      DynamicEnum :xlink_show_attribute_id
      DynamicEnum :file_format_name_id
      String :file_format_version
      Integer :file_size_bytes
      String :checksum
      String :checksum_method

      String :created_by
      String :last_modified_by
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:file_version) do
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end



    create_table(:sequence) do
      String :sequence_name, :primary_key => true
      Integer :value, :null => false
    end


    create_table(:deleted_records) do
      primary_key :id

      String :uri, :null => false
      String :operator, :null => false
      DateTime :timestamp, :null => false
    end


    create_editable_enum('linked_agent_archival_record_relators',
                ['act', 'adp', 'anl', 'anm', 'ann', 'app', 'arc', 'arr', 'acp',
                 'art', 'ard', 'asg', 'asn', 'att', 'auc', 'aut', 'aqt', 'aft',
                 'aud', 'aui', 'aus', 'ant', 'bnd', 'bdd', 'blw', 'bkd', 'bkp',
                 'bjd', 'bpd', 'bsl', 'cll', 'ctg', 'cns', 'chr', 'cng', 'cli',
                 'clb', 'col', 'clt', 'clr', 'cmm', 'cwt', 'com', 'cpl', 'cpt',
                 'cpe', 'cmp', 'cmt', 'ccp', 'cnd', 'con', 'csl', 'csp', 'cos',
                 'cot', 'coe', 'cts', 'ctt', 'cte', 'ctr', 'ctb', 'cpc', 'cph',
                 'crr', 'crp', 'cst', 'cov', 'cre', 'cur', 'dnc', 'dtc', 'dtm',
                 'dte', 'dto', 'dfd', 'dft', 'dfe', 'dgg', 'dln', 'dpc', 'dpt',
                 'dsr', 'drt', 'dis', 'dbp', 'dst', 'drm', 'dub', 'edt', 'elg',
                 'elt', 'eng', 'egr', 'etr', 'evp', 'exp', 'fac', 'fld', 'flm',
                 'fpy', 'frg', 'fmo', 'dnr', 'fnd', 'gis', 'grt', 'hnr', 'hst',
                 'ilu', 'ill', 'ins', 'itr', 'ive', 'ivr', 'inv', 'lbr', 'ldr',
                 'lsa', 'led', 'len', 'lil', 'lit', 'lie', 'lel', 'let', 'lee',
                 'lbt', 'lse', 'lso', 'lgd', 'ltg', 'lyr', 'mfp', 'mfr', 'mrb',
                 'mrk', 'mdc', 'mte', 'mod', 'mon', 'mcp', 'msd', 'mus', 'nrt',
                 'opn', 'orm', 'org', 'oth', 'own', 'ppm', 'pta', 'pth', 'pat',
                 'prf', 'pma', 'pht', 'ptf', 'ptt', 'pte', 'plt', 'prt', 'pop',
                 'prm', 'prc', 'pro', 'pmn', 'prd', 'prp', 'prg', 'pdr', 'pfr',
                 'prv', 'pup', 'pbl', 'pbd', 'ppt', 'rcp', 'rce', 'rcd', 'red',
                 'ren', 'rpt', 'rps', 'rth', 'rtm', 'res', 'rsp', 'rst', 'rse',
                 'rpy', 'rsg', 'rev', 'rbr', 'sce', 'sad', 'scr', 'scl', 'spy',
                 'sec', 'std', 'stg', 'sgn', 'sng', 'sds', 'spk', 'spn', 'stm',
                 'stn', 'str', 'stl', 'sht', 'srv', 'tch', 'tcd', 'ths', 'trc',
                 'trl', 'tyd', 'tyg', 'uvp', 'vdg', 'voc', 'wit', 'wde', 'wdc',
                 'wam'])


    create_editable_enum('linked_event_archival_record_roles',
                ['source', 'outcome', 'transfer'])


    create_editable_enum('linked_agent_event_roles',
                ["authorizer", "executing_program", "implementer", "recipient",
                 "transmitter", "validator"])

    create_editable_enum('name_source', ["local", "naf", "nad", "ulan"])

    create_editable_enum('name_rule', ["local", "aacr", "dacs", "rda"])

    create_editable_enum('accession_acquisition_type', ["deposit", "gift", "purchase", "transfer"])

    create_editable_enum('accession_resource_type', ["collection", "publications", "papers", "records"])

    create_editable_enum('collection_management_processing_priority', ["high", "medium", "low"])

    create_editable_enum('collection_management_processing_status', ["new", "in_progress", "completed"])

    create_editable_enum('date_era', ["ce"])

    create_editable_enum('date_calendar', ["gregorian"])

    create_editable_enum('digital_object_digital_object_type', ["cartographic", "mixed_materials", "moving_image", "notated_music", "software_multimedia", "sound_recording", "sound_recording_musical", "sound_recording_nonmusical", "still_image", "text"])

    create_editable_enum('digital_object_level', ["collection", "work", "image"])

    create_editable_enum('extent_extent_type', ["cassettes", "cubic_feet", "files", "gigabytes", "leaves", "linear_feet", "megabytes", "photographic_prints", "photographic_slides", "reels", "sheets", "terabytes", "volumes"])

    create_editable_enum('event_event_type', ["accession", "accumulation", "acknowledgement", "acknowledgement_sent", "agreement_signed", "agreement_received", "agreement_sent", "appraisal", "assessment", "capture", "cataloging", "collection", "compression", "contribution", "component_transfer", "copyright_transfer", "custody_transfer", "deaccession", "decompression", "decryption", "deletion", "digital_signature_validation", "fixity_check", "ingestion", "message_digest_calculation", "migration", "normalization", "processing", "publication", "replication", "validation", "virus_check"])

    create_editable_enum('container_type', ["box", "carton", "case", "folder", "frame", "object", "page", "reel", "volume"])

    create_editable_enum('agent_contact_salutation', ["mr", "mrs", "ms", "madame", "sir"])

    create_editable_enum('event_outcome', ["pass", "partial pass", "fail"])

    create_editable_enum('resource_resource_type', ["collection", "publications", "papers", "records"])

    create_editable_enum('resource_finding_aid_description_rules', ["aacr", "cco", "dacs", "rad", "isadg"])

    create_editable_enum('resource_finding_aid_status', ["completed", "in_progress", "under_revision", "unprocessed"])

    create_editable_enum('instance_instance_type', ["accession", "audio", "books", "computer_disks", "digital_object","graphic_materials", "maps", "microform", "mixed_materials", "moving_images", "realia", "text"])

    create_editable_enum('subject_source', ["aat", "rbgenr", "tgn", "lcsh", "local", "mesh", "gmgpc"])


    create_editable_enum('file_version_use_statement',
                ["audio-clip",
                 "audio-master",
                 "audio-master-edited",
                 "audio-service",
                 "audio-streaming",
                 "image-master",
                 "image-master-edited",
                 "image-service",
                 "image-service-edited",
                 "image-thumbnail",
                 "text-codebook",
                 "text-data",
                 "text-data_definition",
                 "text-georeference",
                 "text-ocr-edited",
                 "text-ocr-unedited",
                 "text-tei-transcripted",
                 "text-tei-translated",
                 "video-clip",
                 "video-master",
                 "video-master-edited",
                 "video-service",
                 "video-streaming"])

    create_editable_enum('file_version_checksum_methods',
                ["md5", "sha-1", "sha-256", "sha-384", "sha-512"])

    create_enum("language_iso639_2", ["aar","abk","ace","ach","ada","ady","afa","afh","afr","ain","aka","akk","alb","ale","alg","alt","amh","ang","anp","apa","ara","arc","arg","arm","arn","arp","art","arw","asm","ast","ath","aus","ava","ave","awa","aym","aze","bad","bai","bak","bal","bam","ban","baq","bas","bat","bej","bel","bem","ben","ber","bho","bih","bik","bin","bis","bla","bnt","bos","bra","bre","btk","bua","bug","bul","bur","byn","cad","cai","car","cat","cau","ceb","cel","cha","chb","che","chg","chi","chk","chm","chn","cho","chp","chr","chu","chv","chy","cmc","cop","cor","cos","cpe","cpf","cpp","cre","crh","crp","csb","cus","cze","dak","dan","dar","day","del","den","dgr","din","div","doi","dra","dsb","dua","dum","dut","dyu","dzo","efi","egy","eka","elx","eng","enm","epo","est","ewe","ewo","fan","fao","fat","fij","fil","fin","fiu","fon","fre","frm","fro","frr","frs","fry","ful","fur","gaa","gay","gba","gem","geo","ger","gez","gil","gla","gle","glg","glv","gmh","goh","gon","gor","got","grb","grc","gre","grn","gsw","guj","gwi","hai","hat","hau","haw","heb","her","hil","him","hin","hit","hmn","hmo","hrv","hsb","hun","hup","iba","ibo","ice","ido","iii","ijo","iku","ile","ilo","ina","inc","ind","ine","inh","ipk","ira","iro","ita","jav","jbo","jpn","jpr","jrb","kaa","kab","kac","kal","kam","kan","kar","kas","kau","kaw","kaz","kbd","kha","khi","khm","kho","kik","kin","kir","kmb","kok","kom","kon","kor","kos","kpe","krc","krl","kro","kru","kua","kum","kur","kut","lad","lah","lam","lao","lat","lav","lez","lim","lin","lit","lol","loz","ltz","lua","lub","lug","lui","lun","luo","lus","mac","mad","mag","mah","mai","mak","mal","man","mao","map","mar","mas","may","mdf","mdr","men","mga","mic","min","mis","mkh","mlg","mlt","mnc","mni","mno","moh","mon","mos","mul","mun","mus","mwl","mwr","myn","myv","nah","nai","nap","nau","nav","nbl","nde","ndo","nds","nep","new","nia","nic","niu","nno","nob","nog","non","nor","nqo","nso","nub","nwc","nya","nym","nyn","nyo","nzi","oci","oji","ori","orm","osa","oss","ota","oto","paa","pag","pal","pam","pan","pap","pau","peo","per","phi","phn","pli","pol","pon","por","pra","pro","pus","qaa-qtz","que","raj","rap","rar","roa","roh","rom","rum","run","rup","rus","sad","sag","sah","sai","sal","sam","san","sas","sat","scn","sco","sel","sem","sga","sgn","shn","sid","sin","sio","sit","sla","slo","slv","sma","sme","smi","smj","smn","smo","sms","sna","snd","snk","sog","som","son","sot","spa","srd","srn","srp","srr","ssa","ssw","suk","sun","sus","sux","swa","swe","syc","syr","tah","tai","tam","tat","tel","tem","ter","tet","tgk","tgl","tha","tib","tig","tir","tiv","tkl","tlh","tli","tmh","tog","ton","tpi","tsi","tsn","tso","tuk","tum","tup","tur","tut","tvl","twi","tyv","udm","uga","uig","ukr","umb","und","urd","uzb","vai","ven","vie","vol","vot","wak","wal","war","was","wel","wen","wln","wol","xal","xho","yao","yap","yid","yor","ypk","zap","zbl","zen","zha","znd","zul","zun","zxx","zza",])

    create_enum("linked_agent_role", ["creator", "source", "subject"])

    create_enum("agent_relationship_associative_relator", ["is_associative_with"])
    create_enum("agent_relationship_earlierlater_relator", ["is_earlier_form_of", "is_later_form_of"])
    create_enum("agent_relationship_parentchild_relator", ["is_parent_of", "is_child_of"])
    create_enum("agent_relationship_subordinatesuperior_relator", ["is_subordinate_to", "is_superior_of"])

    create_enum("archival_record_level", ["class", "collection", "file", "fonds", "item", "otherlevel", "recordgrp", "series", "subfonds", "subgrp", "subseries"])

    create_enum("container_location_status", ["current", "previous"], "current")

    create_enum("date_type", ["single", "bulk", "inclusive"])
    create_enum("date_label", ["broadcast", "copyright", "creation", "deaccession", "digitized", "event", "issued", "modified", "publication", "agent_relation", "other"])
    create_enum("date_certainty", ["approximate", "inferred", "questionable"])

    create_enum("deaccession_scope", ["whole", "part"], "whole")

    create_enum("extent_portion", ["whole", "part"], "whole")

    create_enum("file_version_xlink_actuate_attribute", ["none", "other", "onLoad", "onRequest"])
    create_enum("file_version_xlink_show_attribute", ["new", "replace", "embed", "other", "none"])
    create_editable_enum("file_version_file_format_name", ["aiff", "avi", "gif", "jpeg", "mp3", "pdf", "tiff", "txt"])

    create_enum("location_temporary", ["conservation", "exhibit", "loan", "reading_room"])

    create_enum("name_person_name_order", ["inverted", "direct"], "inverted")

    create_enum("note_digital_object_type", ["summary", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "edition", "extent", "altformavail", "originalsloc", "note", "acqinfo", "inscription", "langmaterial", "legalstatus", "physdesc", "prefercite", "processinfo", "relatedmaterial"])
    create_enum("note_multipart_type", ["accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial"])
    create_enum("note_orderedlist_enumeration", ["arabic", "loweralpha", "upperalpha", "lowerroman", "upperroman", "null"])
    create_enum("note_singlepart_type", ["abstract", "physdesc", "langmaterial", "physloc", "materialspec", "physfacet"])

    create_enum("country_iso_3166", ["AF", "AX", "AL", "DZ", "AS", "AD", "AO", "AI", "AQ", "AG", "AR", "AM", "AW", "AU", "AT", "AZ", "BS", "BH", "BD", "BB", "BY", "BE", "BZ", "BJ", "BM", "BT", "BO", "BQ", "BA", "BW", "BV", "BR", "IO", "BN", "BG", "BF", "BI", "KH", "CM", "CA", "CV", "KY", "CF", "TD", "CL", "CN", "CX", "CC", "CO", "KM", "CG", "CD", "CK", "CR", "CI", "HR", "CU", "CW", "CY", "CZ", "DK", "DJ", "DM", "DO", "EC", "EG", "SV", "GQ", "ER", "EE", "ET", "FK", "FO", "FJ", "FI", "FR", "GF", "PF", "TF", "GA", "GM", "GE", "DE", "GH", "GI", "GR", "GL", "GD", "GP", "GU", "GT", "GG", "GN", "GW", "GY", "HT", "HM", "VA", "HN", "HK", "HU", "IS", "IN", "ID", "IR", "IQ", "IE", "IM", "IL", "IT", "JM", "JP", "JE", "JO", "KZ", "KE", "KI", "KP", "KR", "KW", "KG", "LA", "LV", "LB", "LS", "LR", "LY", "LI", "LT", "LU", "MO", "MK", "MG", "MW", "MY", "MV", "ML", "MT", "MH", "MQ", "MR", "MU", "YT", "MX", "FM", "MD", "MC", "MN", "ME", "MS", "MA", "MZ", "MM", "NA", "NR", "NP", "NL", "NC", "NZ", "NI", "NE", "NG", "NU", "NF", "MP", "NO", "OM", "PK", "PW", "PS", "PA", "PG", "PY", "PE", "PH", "PN", "PL", "PT", "PR", "QA", "RE", "RO", "RU", "RW", "BL", "SH", "KN", "LC", "MF", "PM", "VC", "WS", "SM", "ST", "SA", "SN", "RS", "SC", "SL", "SG", "SX", "SK", "SI", "SB", "SO", "ZA", "GS", "SS", "ES", "LK", "SD", "SR", "SJ", "SZ", "SE", "CH", "SY", "TW", "TJ", "TZ", "TH", "TL", "TG", "TK", "TO", "TT", "TN", "TR", "TM", "TC", "TV", "UG", "UA", "AE", "GB", "US", "UM", "UY", "UZ", "VU", "VE", "VN", "VG", "VI", "WF", "EH", "YE", "ZM", "ZW"])

    create_enum("rights_statement_rights_type", ["intellectual_property", "license", "statute", "institutional_policy"])
    create_enum("rights_statement_ip_status", ["copyrighted", "public_domain", "unknown"])

    create_enum("subject_term_type", ["cultural_context", "function", "geographic", "genre_form", "occupation", "style_period", "technique", "temporal", "topical", "uniform_title"])

    create_table(:linked_agents_rlshp) do
      primary_key :id

      Integer :agent_person_id
      Integer :agent_software_id
      Integer :agent_family_id
      Integer :agent_corporate_entity_id

      Integer :accession_id
      Integer :archival_object_id
      Integer :digital_object_id
      Integer :digital_object_component_id
      Integer :event_id
      Integer :resource_id

      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
      DateTime :create_time, :index => true

      String :role
      DynamicEnum :role_id
      DynamicEnum :relator_id
    end

    alter_table(:linked_agents_rlshp) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
      add_foreign_key([:event_id], :event, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end


    create_table(:linked_agent_term) do
        primary_key :id

        Integer :linked_agents_rlshp_id, :null => false
        Integer :term_id, :null => false
      end

    alter_table(:linked_agent_term) do
      add_foreign_key([:linked_agents_rlshp_id], :linked_agents_rlshp, :key => :id)
      add_foreign_key([:term_id], :term, :key => :id)
      add_index([:linked_agents_rlshp_id, :term_id], :name => "linked_agent_term_idx")
    end


    # Event relationships
    create_table(:event_link_rlshp) do
      primary_key :id

      Integer :accession_id
      Integer :resource_id
      Integer :archival_object_id
      Integer :digital_object_id
      Integer :agent_person_id
      Integer :agent_family_id
      Integer :agent_corporate_entity_id
      Integer :agent_software_id
      Integer :event_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
      DynamicEnum :role_id
    end

    alter_table(:event_link_rlshp) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      add_foreign_key([:event_id], :event, :key => :id)
    end


    # Accession/resource "spawned from" relationships
    create_table(:spawned_rlshp) do
      primary_key :id
      Integer :accession_id
      Integer :resource_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:spawned_rlshp) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end


    create_table(:subject_rlshp) do
      primary_key :id
      Integer :accession_id
      Integer :archival_object_id
      Integer :resource_id
      Integer :digital_object_id
      Integer :digital_object_component_id
      Integer :subject_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true
    end

    alter_table(:subject_rlshp) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
      add_foreign_key([:subject_id], :subject, :key => :id)
    end


    create_table(:housed_at_rlshp) do
      primary_key :id
      Integer :container_id
      Integer :location_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false, :index => true

      String :status
      String :start_date
      String :end_date
      String :note
    end

    alter_table(:housed_at_rlshp) do
      add_foreign_key([:container_id], :container, :key => :id)
      add_foreign_key([:location_id], :location, :key => :id)
    end


    [:subject, :accession, :archival_object, :collection_management, :digital_object,
     :digital_object_component, :event, :location, :resource].each do |record|
      table = "#{record}_ext_id".intern

      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern, :null => false
        String :external_id, :null => false
        String :source, :null => false
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
      end
    end

  end


  down do

    remaining = tables.reject {|t| t == :schema_info}

    ceiling = 100

    begin
      
      greylist = []
      
      remaining.each do |table|
        foreign_key_list(table).each do |fk|

          next if fk[:table] == table
          if (not greylist.include?(fk[:table])) && remaining.include?(fk[:table])
            greylist << fk[:table]
          end 
        end
      end

      remaining.each do |table|
        if not greylist.include?(table)
          puts "Dropping #{table}"
          drop_table?(table)
        end
      end
      
      remaining = greylist.clone
      ceiling = ceiling - 1
      
    end while (not remaining.empty?) && ceiling > 0

  end
end


