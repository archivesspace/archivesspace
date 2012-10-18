{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/locations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "building" => {"type" => "string", "minLength" => 1, "required" => true},

      "floor" => {"type" => "string", "required" => false},
      "room" => {"type" => "string", "required" => false},
      "area" => {"type" => "string", "required" => false},

      "barcode" => {"type" => "string", "required" => false},
      "classification" => {"type" => "string", "required" => false},

      "coordinate_1_label" => {"type" => "string", "required" => false},
      "coordinate_1_indicator" => {"type" => "string", "required" => false, "pattern" => "^[a-zA-Z0-9]*$"},

      "coordinate_2_label" => {"type" => "string", "required" => false},
      "coordinate_2_indicator" => {"type" => "string", "required" => false, "pattern" => "^[a-zA-Z0-9]*$"},

      "coordinate_3_label" => {"type" => "string", "required" => false},
      "coordinate_3_indicator" => {"type" => "string", "required" => false, "pattern" => "^[a-zA-Z0-9]*$"},

      "temporary" => {"type" => "string", "enum" => ["conservation", "exhibit", "loan", "reading_room"]},

    },

    "additionalProperties" => false,
  },
}
