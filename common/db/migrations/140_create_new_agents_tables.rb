require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts "Creating new database tables for new agents functionality"
    create_table(:agent_record_control) do
      primary_key :id

      Integer :maintenance_status_id, :null => false
      Integer :publication_status_id, :null => true
      Integer :government_agency_type_id, :null => true
      Integer :reference_evaluation_id, :null => true
      Integer :name_type_id, :null => true
      Integer :level_of_detail_id, :null => true
      Integer :modified_record_id, :null => true
      Integer :cataloging_source_id, :null => true
      Integer :language_id, :null => true
      Integer :script_id, :null => true
      Integer :romanization_id, :null => true

      String :maintenance_agency, :null => true
      String :agency_name, :null => true
      String :maintenance_agency_note, :null => true
      String :language_note, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_alternate_set) do
      primary_key :id

      Integer :file_version_xlink_actuate_attribute_id, :null => true
      Integer :file_version_xlink_show_attribute_id, :null => true

      String :set_component, :null => true
      TextField :descriptive_note, :null => true
      String :file_uri, :null => true
      String :xlink_title_attribute, :null => true
      String :xlink_role_attribute, :null => true
      String :xlink_arcrole_attribute, :null => true
      DateTime :last_verified_date, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_conventions_declaration) do
      primary_key :id

      Integer :name_rule_id, :null => true
      Integer :file_version_xlink_actuate_attribute_id, :null => true
      Integer :file_version_xlink_show_attribute_id, :null => true

      String :citation, :null => true
      TextField :descriptive_note, :null => false
      String :file_uri, :null => true
      String :xlink_title_attribute, :null => true
      String :xlink_role_attribute, :null => true
      String :xlink_arcrole_attribute, :null => true
      DateTime :last_verified_date, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_other_agency_codes) do
      primary_key :id

      Integer :agency_code_type_id, :null => true

      String :maintenance_agency, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_maintenance_history) do
      primary_key :id

      Integer :maintenance_event_type_id, :null => false
      Integer :maintenance_agent_type_id, :null => false

      DateTime :event_date, :null => false
      String :agent, :null => false
      TextField :descriptive_note, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_record_identifier) do
      primary_key :id

      Integer :identifier_type_id, :null => true
      Integer :source_id, :null => false

      Integer :primary_identifier, :null => false

      String :record_identifier, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_sources) do
      primary_key :id

      String :source_entry, :null => true
      TextField :descriptive_note, :null => true
      String :file_uri, :null => true
      Integer :file_version_xlink_actuate_attribute_id, :null => true
      Integer :file_version_xlink_show_attribute_id, :null => true

      String :xlink_title_attribute, :null => true
      String :xlink_role_attribute, :null => true
      String :xlink_arcrole_attribute, :null => true

      DateTime :last_verified_date, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    date_std_type_id = get_enum_value_id('date_standardized_type', 'standard')

    create_table(:structured_date_single) do
      primary_key :id
      Integer :structured_date_label_id, :null => false

      Integer :date_role_id, :null => false
      String :date_expression, :null => true
      String :date_standardized, :null => true
      Integer :date_standardized_type_id, :null => false, :default => date_std_type_id

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:structured_date_range) do
      primary_key :id
      Integer :structured_date_label_id, :null => false

      String :begin_date_expression, :null => true
      String :begin_date_standardized, :null => true
      Integer :begin_date_standardized_type_id, :null => false, :default => date_std_type_id

      String :end_date_expression, :null => true
      String :end_date_standardized, :null => true
      Integer :end_date_standardized_type_id, :null => false, :default => date_std_type_id

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:structured_date_label) do
      primary_key :id

      Integer :date_label_id, :null => false # existing enum date_label
      Integer :date_type_structured_id, :null => false
      Integer :date_certainty_id, :null => true # existing enum date_certainty
      Integer :date_era_id, :null => true # existing enum date_era
      Integer :date_calendar_id, :null => true # existing enum date_calendar

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :name_person_id, :null => true
      Integer :name_family_id, :null => true
      Integer :name_corporate_entity_id, :null => true
      Integer :name_software_id, :null => true

      Integer :parallel_name_person_id, :null => true
      Integer :parallel_name_family_id, :null => true
      Integer :parallel_name_corporate_entity_id, :null => true
      Integer :parallel_name_software_id, :null => true

      Integer :related_agents_rlshp_id, :null => true

      Integer :agent_place_id, :null => true
      Integer :agent_occupation_id, :null => true
      Integer :agent_function_id, :null => true
      Integer :agent_topic_id, :null => true

      Integer :agent_gender_id, :null => true

      Integer :agent_resource_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_place) do
      primary_key :id

      Integer :place_role_id, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish
      Integer :suppressed

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_occupation) do
      primary_key :id

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish
      Integer :suppressed

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_function) do
      primary_key :id

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish
      Integer :suppressed

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_topic) do
      primary_key :id

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish
      Integer :suppressed

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end


    create_table(:agent_gender) do
      primary_key :id

      Integer :gender_id, :null => false

      Integer :agent_person_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_identifier) do
      primary_key :id

      Integer :identifier_type_id, :null => true

      String :entity_identifier, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:parallel_name_person) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :name_person_id, :null => false

      String :primary_name, :null => false
      DynamicEnum :name_order_id, :null => false

      Integer :language_id
      Integer :script_id
      Integer :transliteration_id

      HalfLongString :title, :null => true
      TextField :prefix, :null => true
      TextField :rest_of_name, :null => true
      TextField :suffix, :null => true
      TextField :fuller_form, :null => true
      String :number, :null => true

      apply_parallel_name_columns

      apply_mtime_columns
    end

    create_table(:parallel_name_family) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :name_family_id, :null => false

      String :family_type
      String :location

      Integer :language_id
      Integer :script_id
      Integer :transliteration_id

      TextField :family_name, :null => false

      TextField :prefix, :null => true

      apply_parallel_name_columns

      apply_mtime_columns
    end

    create_table(:parallel_name_corporate_entity) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :name_corporate_entity_id, :null => false

      String :location
      Integer :jurisdiction, :default => 0
      Integer :conference_meeting, :default => 0

      Integer :language_id
      Integer :script_id
      Integer :transliteration_id

      TextField :primary_name, :null => false

      TextField :subordinate_name_1, :null => true
      TextField :subordinate_name_2, :null => true
      String :number, :null => true

      apply_parallel_name_columns

      apply_mtime_columns
    end

    create_table(:parallel_name_software) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :name_software_id, :null => false

      Integer :language_id
      Integer :script_id
      Integer :transliteration_id

      TextField :software_name, :null => false

      TextField :version, :null => true
      TextField :manufacturer, :null => true

      apply_parallel_name_columns

      apply_mtime_columns
    end

    create_table(:used_language) do
      primary_key :id

      DynamicEnum :language_id, :null => true
      DynamicEnum :script_id, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:agent_resource) do
      primary_key :id

      Integer :linked_agent_role_id, :null => false

      String :linked_resource, :null => false
      TextField :linked_resource_description, :null => true
      String :file_uri, :null => true

      Integer :file_version_xlink_actuate_attribute_id, :null => true
      Integer :file_version_xlink_show_attribute_id, :null => true

      String :xlink_title_attribute, :null => true
      String :xlink_role_attribute, :null => true
      String :xlink_arcrole_attribute, :null => true
      DateTime :last_verified_date, :null => true

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish
      Integer :suppressed

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    create_table(:subject_agent_subrecord_rlshp) do
      primary_key :id

      Integer :subject_id, :null => true
      Integer :agent_function_id, :null => true
      Integer :agent_occupation_id, :null => true
      Integer :agent_place_id, :null => true
      Integer :agent_topic_id, :null => true

      Integer :aspace_relationship_position
      Integer :suppressed, :default => 0, :null => false

      apply_mtime_columns(false)
    end

    create_table(:subject_agent_subrecord_place_rlshp) do
      primary_key :id

      Integer :subject_id, :null => true
      Integer :agent_function_id, :null => true
      Integer :agent_occupation_id, :null => true
      Integer :agent_resource_id, :null => true
      Integer :agent_topic_id, :null => true

      Integer :aspace_relationship_position
      Integer :suppressed, :default => 0, :null => false

      apply_mtime_columns(false)
    end
  end
end
