{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/locations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false, "readonly" => true},

      "title" => {"type" => "string", "readonly" => true},

      "external_ids" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "external_id" => {"type" => "string"},
            "source" => {"type" => "string"},
          }
        }
      },

      "building" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},

      "floor" => {"type" => "string", "required" => false},
      "room" => {"type" => "string", "required" => false},
      "area" => {"type" => "string", "required" => false},

      "barcode" => {"type" => "string", "required" => false},
      "classification" => {"type" => "string", "required" => false},

      "coordinate_1_label" => {"type" => "string", "required" => false},
      "coordinate_1_indicator" => {"type" => "string", "required" => false},

      "coordinate_2_label" => {"type" => "string", "required" => false},
      "coordinate_2_indicator" => {"type" => "string", "required" => false},

      "coordinate_3_label" => {"type" => "string", "required" => false},
      "coordinate_3_indicator" => {"type" => "string", "required" => false},

      "temporary" => {"type" => "string", "enum" => ["conservation", "exhibit", "loan", "reading_room"]},

    },

    "additionalProperties" => false,
  },
}
