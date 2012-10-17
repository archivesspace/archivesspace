{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error"},

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "label" => {"type" => "string", "ifmissing" => "error"},
            "value" => {"type" => "string", "ifmissing" => "error"}
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
