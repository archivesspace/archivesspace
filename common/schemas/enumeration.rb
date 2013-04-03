{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/config/enumerations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "default_value" => {"type" => "string"},
      "values" => {
        "type" => "array",
        "ifmissing" => "error",
        "items" => {
          "type" => "string",
        }
      },
    },

    "additionalProperties" => false,
  },
}
