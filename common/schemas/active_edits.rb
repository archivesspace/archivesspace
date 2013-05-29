{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "active_edits" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "user" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
            "uri" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
            "time" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
