{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/locations",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {"type" => "string", "readonly" => true},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

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

      "temporary" => {"type" => "string", "dynamic_enum" => "location_temporary"},

      "location_profile" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:location_profile) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "owner_repo" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:repository) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "functions" => {"type" => "array", "items" => {"type" => "JSONModel(:location_function) object"}},

    },
  },
}
