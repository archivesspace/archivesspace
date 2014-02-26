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
            "label" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000},
            "value" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000}
          }
        }
      }
    },
  },
}
