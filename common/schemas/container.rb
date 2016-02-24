{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      
      "container_profile_key" => {"type" => "string"},

      "type_1" => {"type" => "string", "dynamic_enum" => "container_type", "required" => false},
      "indicator_1" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "required" => false },
      "barcode_1" => {"type" => "string", "maxLength" => 255, "minLength" => 1},

      "type_2" => {"type" => "string", "dynamic_enum" => "container_type"},
      "indicator_2" => {"type" => "string", "maxLength" => 255},

      "type_3" => {"type" => "string", "dynamic_enum" => "container_type"},
      "indicator_3" => {"type" => "string", "maxLength" => 255},

      "container_extent" => {"type" => "string", "maxLength" => 255, "required" => false},
      "container_extent_type" => {"type" => "string", "required" => false, "dynamic_enum" => "extent_extent_type"},

      "container_locations" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:container_location) object",
        }
      }
    },
  },
}
