{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/locations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {"type" => "string", "readonly" => true},

      "external_ids" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "external_id" => {"type" => "string", "maxLength" => 255},
            "source" => {"type" => "string", "maxLength" => 255},
          }
        }
      },

      "building" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},

      "floor" => {"type" => "string", "maxLength" => 255, "required" => false},
      "room" => {"type" => "string", "maxLength" => 255, "required" => false},
      "area" => {"type" => "string", "maxLength" => 255, "required" => false},

      "barcode" => {"type" => "string", "maxLength" => 255, "required" => false},
      "classification" => {"type" => "string", "maxLength" => 255, "required" => false},

      "coordinate_1_label" => {"type" => "string", "maxLength" => 255, "required" => false},
      "coordinate_1_indicator" => {"type" => "string", "maxLength" => 255, "required" => false},

      "coordinate_2_label" => {"type" => "string", "maxLength" => 255, "required" => false},
      "coordinate_2_indicator" => {"type" => "string", "maxLength" => 255, "required" => false},

      "coordinate_3_label" => {"type" => "string", "maxLength" => 255, "required" => false},
      "coordinate_3_indicator" => {"type" => "string", "maxLength" => 255, "required" => false},

      "temporary" => {"type" => "string", "enum" => ["conservation", "exhibit", "loan", "reading_room"]},

    },

    "additionalProperties" => false,
  },
}
