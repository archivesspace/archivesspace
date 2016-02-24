{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/config/enumerations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "default_value" => {"type" => "string"},
      "editable" => {"type" => "boolean", "readonly" => true},
      "relationships" => {
        "type" => "array",
        "items" => {
          "type" => "string",
        }
      },
      "enumeration_values" => {"type" => "array", "items" => {"type" => "JSONModel(:enumeration_value) object"}},
      "values" => {
        "type" => "array",
        "ifmissing" => "error",
        "items" => {
          "type" => "string",
        }
      },
      "readonly_values" => {
        "type" => "array",
        "readonly" => true,
        "items" => {
          "type" => "string",
        }
      }
    },
  },
}
