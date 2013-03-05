{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error"},

      "publish" => {"type" => "boolean", "default" => true},
      "internal" => {"type" => "boolean", "default" => false},

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "event_date" => {"type" => "date"},
            "events" => {
              "type" => "array",
              "items" => {"type" => "string"}
            }
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
