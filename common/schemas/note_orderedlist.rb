{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error"},

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
          "type" => "string"
        }
      }
    },

    "additionalProperties" => false,
  },
}
