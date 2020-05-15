{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "top_container" => {
        "type" => "object",
        "subtype" => "ref",
        "ifmissing" => "error",
        "properties" => {
          "ref" => {
            "type" => "JSONModel(:top_container) uri",
            "ifmissing" => "error",
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "type_2" => {"type" => "string", "dynamic_enum" => "container_type"},
      "indicator_2" => {"type" => "string", "maxLength" => 255},
      "barcode_2" => {"type" => "string", "maxLength" => 255},

      "type_3" => {"type" => "string", "dynamic_enum" => "container_type"},
      "indicator_3" => {"type" => "string", "maxLength" => 255},

      "display_string" => {"type" => "string", "readonly" => true},
    },
  },
}
