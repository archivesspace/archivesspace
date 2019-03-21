browse_column_enums = {
  'accession' => [
    "title", "publish", "subjects", "agents", "identifier", "acquisition_type",
    "accession_date", "resource_type", "restrictions_apply", "access_restrictions",
    "use_restrictions", "is_slug_auto"
  ],
  'resource' => [
    "title", "publish", "level", "finding_aid_title",
    "finding_aid_filing_title", "identifier", "resource_type", "language", "restrictions", "ead_id",
    "finding_aid_status", "is_slug_auto", "subjects"
  ],
  'archival_object' => [
    "title", "publish", "context", "component_id", "ref_id", "is_slug_auto", "subjects",
    "agents", "level"
  ],
  'digital_object' => [
    "title", "publish", "subjects", "agents", "level", "context",
    "digital_object_type", "digital_object_id", "restrictions", "is_slug_auto"
  ],
  'digital_object_component' => [
    "title", "publish", "subjects", "agents", "creators", "context", "is_slug_auto"
  ],
  'subjects' => [
    "title", "publish", "source", "first_term_type", "is_slug_auto"
  ],
  'agent' => [
    "title", "primary_type", "publish", "authority_id", "source", "rules", "is_slug_auto", "is_user"
  ],
  'location' => [
    "title", "publish", "building", "floor", "room", "area", "location_holdings",
    "location_profile_display_string_u_ssort", 'temporary'
  ],
  'event' => [
    "agents", "event_type", "outcome", "linked_records"
  ],
  'collection_management' => [
    "parent_title", "parent_type", "processing_priority", "processing_status", "processing_hours_total",
    "processing_funding_source", "processors"
  ],
  'classification' => [
    "title", "publish", "has_classification_terms", "is_slug_auto"
  ],
  'top_container' => [
    "title", "publish", "container_profile_display_string_u_sstr", "location_display_string_u_sstr", "type",
    "indicator", "barcode", "context"
  ],
  'assessment' => [
    "assessment_id", "assessment_records", "assessment_record_types", "assessment_surveyors",
    "assessment_survey_begin", "assessment_review_required", "assessment_sensitive_material",
    "assessment_inactive", "assessment_survey_year", "assessment_collections",
    "assessment_completed", "assessment_formats", "assessment_ratings",
    "assessment_conservation_issues"
  ],
  'repositories' => [
    "title", "publish", "is_slug_auto"
  ],
  'container_profile' => [
    "title", "publish", "container_profile_width_u_sstr", "container_profile_height_u_sstr",
    "container_profile_depth_u_sstr", "container_profile_dimension_units_u_sstr"
  ],
  'location_profile' => [
    "title", "publish", "location_profile_width_u_sstr", "location_profile_height_u_sstr",
    "location_profile_depth_u_sstr", "location_profile_dimension_units_u_sstr"
  ],
  'multi' => [
    "primary_type", "title", "context", "identifier", "audit_info"
  ]
}

browse_columns = {}
browse_column_enums.keys.each do |type|
  Array(1..AppConfig[:max_search_columns]).each do |i|
    browse_columns["#{type}_browse_column_#{i}"] = {
      "type" => "string",
      "enum" => browse_column_enums[type] + ['audit_info', 'no_value'],
      "required" => false
    }
  end
end

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "show_suppressed" =>  {"type" => "boolean", "required" => false},
      "publish" =>  {"type" => "boolean", "required" => false},

      "default_values" => {
        "type" => "boolean",
        "required" => false,
        "default" => false
      },

      "note_order" => {
        "type" => "array",
        "items" => {"type" => "string"}
      }

    }.merge(browse_columns),
  },
}
