browse_column_enums = {
  'accession' => [
    "title", "suppressed", "publish", "system_generated", "subjects","agents", "identifier", 
    "acquisition_type", "accession_date", "resource_type", "restrictions_apply", "access_restrictions",
    "use_restrictions", "is_slug_auto"
  ],
  'resource' => [
    "title", "suppressed", "publish", "system_generated", "notes", "level", "finding_aid_title", 
    "finding_aid_filing_title", "identifier", "resource_type", "language", "restrictions", "ead_id", 
    "finding_aid_status", "is_slug_auto"
  ],
  'digital_object' => [
    "title", "suppressed", "publish", "system_generated", "subjects", "agents", "notes", "level", 
    "digital_object_type", "digital_object_id", "restrictions", "is_slug_auto"
  ],
  'subject' => [
    "title", "suppressed", "publish", "system_generated", "source", "first_term_type", 
    "is_slug_auto", "used_within_repository", "used_within_published_repository"
  ]
}

browse_columns = {}
browse_column_enums.keys.each do |type|
  Array(1..5).each do |i|
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
