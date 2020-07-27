{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "maxLength" => 16384},

      "publish" => {"type" => "boolean"},

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "event_date" => {"type" => "string", "maxLength" => 255},
            "place" => {"type" => "string", "maxLength" => 255},
            "events" => {
              "type" => "array",
              "items" => {"type" => "string", "maxLength" => 65000}
            }
          }
        }
      }
    },
  },
}
