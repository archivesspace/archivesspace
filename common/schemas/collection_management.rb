{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/collection_management",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "parent" => {
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
        "properties" => {
          "ref" => {"type" => [{ "type" => "JSONModel(:resource) uri"},
                               { "type" => "JSONModel(:digital_object) uri"},
                               { "type" => "JSONModel(:accession) uri" }]},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        },
      },

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "processing_hours_per_foot_estimate" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_total_extent" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_total_extent_type" => {"type" => "string", "required" => false, "dynamic_enum" => "extent_extent_type"},
      "processing_hours_total" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_plan" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "processing_priority" => {"type" => "string", "required" => false, "dynamic_enum" => "collection_management_processing_priority"},
      "processing_funding_source" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "processors" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "rights_determined" => {"type" => "boolean", "default" => false},
      "processing_status" => {"type" => "string", "required" => false, "dynamic_enum" => "collection_management_processing_status"}
    },
  }
}
