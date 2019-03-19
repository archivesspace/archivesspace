browse_column_enums = {
  'accession' => [
    "title", "publish", "subjects", "agents", "identifier", "acquisition_type", 
    "accession_date", "resource_type", "restrictions_apply", "access_restrictions",
    "use_restrictions", "is_slug_auto"
  ],
  'resource' => [
    "title", "publish", "level", "finding_aid_title", 
    "finding_aid_filing_title", "identifier", "resource_type", "language", "restrictions", "ead_id", 
    "finding_aid_status", "is_slug_auto"
  ],
  'digital_object' => [
    "title", "publish", "subjects", "agents", "level", 
    "digital_object_type", "digital_object_id", "restrictions", "is_slug_auto"
  ],
  'subjects' => [
    "title", "publish", "source", "first_term_type", "is_slug_auto"
  ],
  'agent' => [
    "title", "primary_type", "publish", "used_within_repository", "authority_id", "source", 
    "rules", "is_slug_auto", "is_user"
  ],
  'assessment' => [
    "publish", "assessment_id", 
    "assessment_records", "assessment_record_types", "assessment_surveyors", 
    "assessment_survey_begin", "assessment_review_required", "assessment_sensitive_material", 
    "assessment_inactive", "assessment_survey_year", "assessment_collections", 
    "assessment_completed", "assessment_formats", "assessment_ratings", 
    "assessment_conservation_issues"
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
