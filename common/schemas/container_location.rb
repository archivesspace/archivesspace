{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "status" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["current", "previous"]},
      "start_date" => {"type" => "date", "minLength" => 1, "required" => true},
      "end_date" => {"type" => "date"},
      "note" => {"type" => "string"},

      "location" => {"type" => "JSONModel(:location) uri_or_object"},
    },

    "additionalProperties" => false,
  },
}
