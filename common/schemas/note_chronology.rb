{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "ifmissing" => "error", "maxLength" => 16384},

      "publish" => {"type" => "boolean", "default" => true},

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "event_date" => {"type" => "date"},
            "events" => {
              "type" => "array",
              "items" => {"type" => "string", "maxLength" => 65000}
            }
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
