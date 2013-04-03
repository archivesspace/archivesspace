{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error", "maxLength" => 32672},

      "publish" => {"type" => "boolean", "default" => true},
      "internal" => {"type" => "boolean", "default" => false},

      "enumeration" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => ["arabic", "loweralpha", "upperalpha", "lowerroman", "upperroman", "null"]
      },

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "string",
          "maxLength" => 32672
        }
      }
    },

    "additionalProperties" => false,
  },
}
