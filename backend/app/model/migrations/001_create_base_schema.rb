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
      DateTime :last_modified, :null => false
      Integer :expirable, :default => 1

      TextBlobField :session_data, :null => true
    end


    create_table(:enumeration) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :name, :null => false, :unique => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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
      DateTime :last_modified, :null => false
      String :pwhash, :null => false
    end


    create_table(:webhook_endpoint) do
      primary_key :id
      String :url, :unique => true, :null => false
    end


    create_table(:user) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :username, :null => false, :unique => true
      String :name, :null => false
      String :source, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:repository) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :repo_code, :null => false, :unique => true
      String :name, :null => false
      String :org_code
      String :parent_institution_name
      String :address_1
      String :address_2
      String :city
      String :district
      String :country
      String :post_code
      String :telephone
      String :telephone_ext
      String :fax
      String :email
      String :email_signature
      String :url
      String :image_url

      Integer :hidden, :default => 0

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:group) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      String :group_code, :null => false
      String :group_code_norm, :null => false
      TextField :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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
      DateTime :last_modified, :null => false
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

      Integer :repo_id, :null => false
      Integer :suppressed, :default => 0, :null => false

      String :identifier, :null => false

      TextField :title, :null => true
      TextField :content_description, :null => true
      TextField :condition_description, :null => true

      String :acquisition_type, :null => true

      DateTime :accession_date, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:accession) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_unique_constraint([:repo_id, :identifier], :name => "accession_unique_identifier")
      add_index(:suppressed)
    end

    create_table(:resource) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false
      Integer :accession_id, :null => true
      TextField :title, :null => false

      String :identifier

      String :language, :null => false

      String :level, :null => false
      String :other_level

      String :resource_type, :null => true

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
      String :finding_aid_description_rules
      String :finding_aid_language
      String :finding_aid_sponsor
      TextField :finding_aid_edition_statement
      TextField :finding_aid_series_statement
      String :finding_aid_revision_date
      TextField :finding_aid_revision_description
      String :finding_aid_status
      TextField :finding_aid_note

      BlobField :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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

      Integer :repo_id, :null => false

      Integer :root_record_id, :null => true
      Integer :parent_id, :null => true
      String :parent_name, :null => true
      Integer :position, :null => true

      String :ref_id, :null => false, :unique => false
      String :component_id, :null => true

      TextField :title, :null => true
      Integer :title_auto_generate

      String :level, :null => false
      String :other_level

      String :language, :null => true

      BlobField :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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

      Integer :repo_id, :null => false
      String :digital_object_id, :null => false
      TextField :title
      String :level
      String :digital_object_type
      String :language

      Integer :publish
      Integer :restrictions

      BlobField :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:digital_object) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_index([:repo_id, :digital_object_id], :unique => true)
    end


    create_table(:digital_object_component) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false
      Integer :root_record_id, :null => true
      Integer :parent_id, :null => true
      Integer :position, :null => true
      String :parent_name, :null => true

      String :component_id, :null => false
      TextField :title
      String :label
      String :language

      BlobField :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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

      Integer :resource_id
      Integer :archival_object_id

      String :instance_type, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:instance) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end

    # Instance relationships
    [:digital_object].each do |record|
      table = [MigrationUtils.shorten_table("instance"),
               MigrationUtils.shorten_table(record)].sort.join("_link_").intern


      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern
        Integer :instance_id
        Integer :aspace_relationship_position
        DateTime :last_modified, :null => false
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
        add_foreign_key([:instance_id], :instance, :key => :id)
      end
    end


    create_table(:container) do
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

    alter_table(:container) do
      add_foreign_key([:instance_id], :instance, :key => :id)
    end


    create_table(:vocabulary) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :name, :null => false, :unique => true
      String :ref_id, :null => false, :unique => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    self[:vocabulary].insert(:name => "global", :ref_id => "global",
                               :create_time => Time.now, :last_modified => Time.now)


    create_table(:subject) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :vocab_id, :null => false

      TextField :title
      String :terms_sha1, :unique => true
      String :ref_id, :unique => true

      String :source, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:subject) do
      add_foreign_key([:vocab_id], :vocabulary, :key => :id)
    end


    create_table(:term) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :vocab_id, :null => false

      String :term, :null => false
      String :term_type, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:term) do
      add_foreign_key([:vocab_id], :vocabulary, :key => :id)
      add_index([:vocab_id, :term, :term_type], :unique => true)
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
        Integer :source_id, :null => true
        Integer :rules_id, :null => true
        TextField :sort_name, :null => false
        Integer :sort_name_auto_generate
      end
    end


    def create_enum(name, values)
      id = self[:enumeration].insert(:name => name,
                                     :create_time => Time.now,
                                     :last_modified => Time.now)

      values.each do |value|
        self[:enumeration_value].insert(:enumeration_id => id, :value => value)
      end
    end


    create_table(:name_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :agent_person_id, :null => false

      String :primary_name, :null => false
      String :name_order, :null => false

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
      add_foreign_key([:rules_id], :enumeration_value, :key => :id)
      add_foreign_key([:source_id], :enumeration_value, :key => :id)
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
      add_foreign_key([:rules_id], :enumeration_value, :key => :id)
      add_foreign_key([:source_id], :enumeration_value, :key => :id)
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
      add_foreign_key([:rules_id], :enumeration_value, :key => :id)
      add_foreign_key([:source_id], :enumeration_value, :key => :id)
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
      add_foreign_key([:rules_id], :enumeration_value, :key => :id)
      add_foreign_key([:source_id], :enumeration_value, :key => :id)
    end


    create_table(:agent_contact) do
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
      TextField :note, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:agent_contact) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    create_table(:deaccession) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true

      String :scope, :null => false
      String :description, :null => false

      String :reason
      String :disposition

      Integer :notification

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    alter_table(:deaccession) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end


    create_table(:extent) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :deaccession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true


      String :portion, :null => false
      String :number, :null => false
      String :extent_type, :null => false

      String :container_summary, :null => true
      String :physical_details, :null => true
      String :dimensions, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:extent) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:deaccession_id], :deaccession, :key => :id)
    end


    create_table(:date) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :deaccession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :event_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

      String :date_type, :null => true
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


    create_table(:event) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :suppressed, :default => 0, :null => false

      Integer :repo_id, :null => false

      String :event_type, :null => false
      String :outcome, :null => true
      String :outcome_note, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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
    end


    create_table(:rights_statement) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

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

      TextField :permissions, :null => true
      TextField :restrictions, :null => true
      DateTime :restriction_start_date, :null => true
      DateTime :restriction_end_date, :null => true

      String :granted_note, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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

      TextField :title, :null => false
      String :location, :null => false

      Integer :publish

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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

      Integer :repo_id, :null => false

      String :building, :null => false

      TextField :title

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

    alter_table(:location) do
      add_foreign_key([:repo_id], :repository, :key => :id)
    end


    create_table(:collection_management) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      TextField :cataloged_note, :null => true
      String :processing_hours_per_foot_estimate, :null => true
      String :processing_total_extent, :null => true
      String :processing_total_extent_type, :null => true
      String :processing_hours_total, :null => true
      TextField :processing_plan, :null => true
      String :processing_priority, :null => true
      String :processing_status, :null => true
      TextField :processors, :null => true
      Integer :rights_determined, :default => 0, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
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


    create_enum('linked_agent_archival_record_roles',
                ['creator', 'source', 'subject'])


    create_enum('linked_agent_archival_record_relators',
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


    create_enum('linked_event_archival_record_roles',
                ['source', 'outcome', 'transfer'])


    create_enum('linked_agent_event_roles',
                ["authorizer", "executing_program", "implementer", "recipient",
                 "transmitter", "validator"])

    create_enum('name_source', ["local", "naf", "nad", "ulan"])

    create_enum('name_rule', ["local", "aacr", "dacs"])

    create_enum('name_description_type', ["biographical statement", "administrative history"])

    create_enum('accession_acquisition_type', ["deposit", "gift", "purchase", "transfer"])

    create_enum('collection_management_processing_priority', ["high", "medium", "low"])

    create_enum('collection_management_processing_status', ["new", "in_progress", "completed"])

    create_enum('date_era', ["ce"])

    create_enum('date_calendar', ["gregorian"])

    create_enum('digital_object_digital_object_type', ["cartographic", "mixed_materials", "moving_image", "notated_music", "software_multimedia", "sound_recording", "sound_recording_musical", "sound_recording_nonmusical", "still_image", "text"])

    create_enum('digital_object_level', ["collection", "work", "image"])

    create_enum('extent_extent_type', ["cassettes", "cubic_feet", "leaves", "linear_feet", "photographic_prints", "photographic_slides", "reels", "sheets", "volumes"])

    create_enum('event_event_type', ["accession", "accumulation", "acknowledgement", "agreement received", "agreement sent", "appraisal", "assessment", "capture", "cataloging", "collection", "compression", "contribution", "custody transfer", "deaccession", "decompression", "decryption", "deletion", "digital signature validation", "fixity check", "ingestion", "message digest calculation", "migration", "normalization", "processing", "publication", "replication", "resource merge", "resource component transfer", "validation", "virus check"])

    create_enum('container_type', ["box", "carton", "case", "folder", "frame", "object", "page", "reel", "volume"])

    create_enum('agent_contact_salutation', ["mr", "mrs", "ms", "madame", "sir"])

    create_enum('event_outcome', ["pass", "partial pass", "fail"])

    create_enum('resource_resource_type', ["collection", "publications", "papers", "records"])

    create_enum('resource_finding_aid_description_rules', ["aacr", "cco", "dacs", "rad", "isadg"])

    create_enum('resource_finding_aid_status', ["completed", "in_progress", "under_revision", "unprocessed"])

    create_enum('instance_instance_type', ["audio", "books", "computer_disks", "digital_object","graphic_materials", "maps", "microform", "mixed_materials", "moving_images", "realia", "text"])

    create_enum('subject_source', ["aat", "rbgenr", "tgn", "lcsh", "local", "mesh", "gmgpc"])



    # Relationship tables
    [:accession, :archival_object, :digital_object, :digital_object_component, :event, :resource].each do |record|
      [:agent_person, :agent_software, :agent_family, :agent_corporate_entity, :user].each do |agent|
        table = [MigrationUtils.shorten_table(record),
                 MigrationUtils.shorten_table(agent)].sort.join("_linked_agents_").intern

        create_table(table) do
          primary_key :id
          Integer "#{record}_id".intern
          Integer "#{agent}_id".intern
          Integer :aspace_relationship_position
          DateTime :last_modified, :null => false
          Integer :role_id
          Integer :relator_id
        end

        alter_table(table) do
          add_foreign_key(["#{record}_id".intern], record, :key => :id)
          add_foreign_key(["#{agent}_id".intern], agent, :key => :id)
          add_foreign_key([:role_id], :enumeration_value, :key => :id)
          add_foreign_key([:relator_id], :enumeration_value, :key => :id)
        end
      end
    end

    # Event relationships
    [:accession, :resource, :archival_object, :digital_object, :agent_person, :agent_family, :agent_corporate_entity, :agent_software].each do |record|
      table = [MigrationUtils.shorten_table("event"),
               MigrationUtils.shorten_table(record)].sort.join("_link_").intern

      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern
        Integer :event_id
        Integer :aspace_relationship_position
        DateTime :last_modified, :null => false
        Integer :role_id
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
        add_foreign_key([:event_id], :event, :key => :id)
        add_foreign_key(["role_id".intern], :enumeration_value, :key => :id)
      end
    end


    # Collection management relationships
    [:accession, :resource, :digital_object].each do |record|
      table = [MigrationUtils.shorten_table("collection_management"),
               MigrationUtils.shorten_table(record)].sort.join("_link_").intern


      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern
        Integer :collection_management_id
        Integer :aspace_relationship_position
        DateTime :last_modified, :null => false
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
        add_foreign_key([:collection_management_id], :collection_management, :key => :id)
      end
    end


    # Accession/resource "spawned from" relationships
    table = [MigrationUtils.shorten_table("accession"),
             MigrationUtils.shorten_table("resource")].sort.join("_spawned_").intern

    create_table(table) do
      primary_key :id
      Integer :accession_id
      Integer :resource_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false
    end

    alter_table(table) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end


    # Subject relationships
    [:accession, :archival_object, :resource, :digital_object, :digital_object_component].each do |record|
      table = [MigrationUtils.shorten_table("subject"),
               MigrationUtils.shorten_table(record)].sort.join("_subject_").intern


      create_table(table) do
        primary_key :id
        Integer "#{record}_id".intern
        Integer :subject_id
        Integer :aspace_relationship_position
        DateTime :last_modified, :null => false
      end

      alter_table(table) do
        add_foreign_key(["#{record}_id".intern], record, :key => :id)
        add_foreign_key([:subject_id], :subject, :key => :id)
      end
    end

    # Container/location relationships
    table = [MigrationUtils.shorten_table("location"),
             MigrationUtils.shorten_table("container")].sort.join("_housed_at_").intern

    create_table(table) do
      primary_key :id
      Integer :container_id
      Integer :location_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false

      String :status
      String :start_date
      String :end_date
      String :note
    end

    alter_table(table) do
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


