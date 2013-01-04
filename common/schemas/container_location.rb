{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "status" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["current", "previous"]},
      "start_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
      "end_date" => {"type" => "date"},
      "note" => {"type" => "string"},
      "ref" => {"type" => "JSONModel(:location) uri", "ifmissing" => "error"}
    },

    "additionalProperties" => false,
  },
}
