{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "type_1" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},
      "indicator_1" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},
      "barcode_1" => {"type" => "string", "minLength" => 1},

      "type_2" => {"type" => "string"},
      "indicator_2" => {"type" => "string"},

      "type_3" => {"type" => "string"},
      "indicator_3" => {"type" => "string"},

      "container_locations" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {

            "status" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["current", "previous"]},
            "start_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
            "end_date" => {"type" => "date"},
            "note" => {"type" => "string"},

            "ref" => {"type" => "JSONModel(:location) uri",
                      "ifmissing" => "error"}
          }
        }
      }
    },

    "additionalProperties" => false,
  },
}
