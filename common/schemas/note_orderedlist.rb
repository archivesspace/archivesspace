{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error", "maxLength" => 16384},

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
          "maxLength" => 65000
        }
      }
    },

    "additionalProperties" => false,
  },
}
