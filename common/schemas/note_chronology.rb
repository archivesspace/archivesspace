{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error", "maxLength" => 32672},

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
              "items" => {"type" => "string", "maxLength" => 32672}
            }
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
