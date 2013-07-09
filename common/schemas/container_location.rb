{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "status" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "container_location_status"},
      "start_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
      "end_date" => {"type" => "date"},
      "note" => {"type" => "string"},
      "ref" => {"type" => "JSONModel(:location) uri", "ifmissing" => "error"},
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    },
  },
}
