{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "id" => {"type" => "integer", "ifmissing" => "error"},
      "record_uri" => {"type" => "string", "ifmissing" => "error"},
      "title" => {"type" => "string", "minLength" => 1, "required" => false, "maxLength" => 16384},
      "parsed_title" => {"type" => "string", "required" => false, "maxLength" => 16384},
      "level" => {"type" => "string", "required" => false, "maxLength" => 255},
      "containers" => {
        "type" => "array",
        "required" => false,
        "items" => {
          "type" => "object",
          "properties" => {
            "instance_type" => {"type" => "string", "required" => false},
            "top_container_type" => {"type" => "string", "required" => false},
            "top_container_indicator" => {"type" => "string", "required" => false},
            "top_container_barcode" => {"type" => "string", "required" => false},
            "type_2" => {"type" => "string", "required" => false},
            "indicator_2" => {"type" => "string", "required" => false},
            "barcode_2" => {"type" => "string", "required" => false},
            "type_3" => {"type" => "string", "required" => false},
            "indicator_3" => {"type" => "string", "required" => false},
          }
        }
      },
      "suppressed" => {"type" => "boolean", "default" => false},
      "publish" => {"type" => "boolean"},
      "has_children" => {"type" => "boolean", "readonly" => true},
      "node_type" => {"type" => "string", "maxLength" => 255},
    },
  },
}
