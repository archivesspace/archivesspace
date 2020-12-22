{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "date_label" => {"type" => "string", "dynamic_enum" => "date_label", "ifmissing" => "error"},
      "date_type_structured" => {"type" => "string", "dynamic_enum" => "date_type_structured", "ifmissing" => "error"},
      "structured_date_single" => {"required" => false, "type" => "JSONModel(:structured_date_single) object"},
      "structured_date_range" => {"required" => false, "type" => "JSONModel(:structured_date_range) object"},
      "date_certainty" => {"type" => "string", "dynamic_enum" => "date_certainty"},
      "date_era" => {"type" => "string", "dynamic_enum" => "date_era"},
      "date_calendar" => {"type" => "string", "dynamic_enum" => "date_calendar"}
    },
  },
}
