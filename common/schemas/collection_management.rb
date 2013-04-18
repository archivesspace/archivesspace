{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/collection_management",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

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

      "cataloged_note" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "processing_hours_per_foot_estimate" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_total_extent" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_total_extent_type" => {"type" => "string", "required" => false, "dynamic_enum" => "extent_extent_type"},
      "processing_hours_total" => {"type" => "string", "maxLength" => 255, "required" => false},
      "processing_plan" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "processing_priority" => {"type" => "string", "required" => false, "dynamic_enum" => "collection_management_processing_priority"},
      "processing_status" => {"type" => "string", "required" => false, "dynamic_enum" => "collection_management_processing_status"},
      "processing_funding_source" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "processors" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "rights_determined" => {"type" => "boolean", "default" => false},

    },

    "additionalProperties" => false
  }
}
