{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/collection_management_records",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

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

      "cataloged_note" => {"type" => "string", "required" => false},
      "processing_hours_per_foot_estimate" => {"type" => "string", "required" => false},
      "processing_total_extent" => {"type" => "string", "required" => false},
      "processing_total_extent_type" => {"type" => "string", "required" => false, "enum" => ["cassettes", "cubic_feet", "leafs", "linear_feet", "photographic_prints", "photographic_slides", "reels", "sheets", "volumes"]},
      "processing_hours_total" => {"type" => "string", "required" => false},
      "processing_plan" => {"type" => "string", "required" => false},
      "processing_priority" => {"type" => "string", "required" => false, "enum" => ["high", "medium", "low"]},
      "processing_status" => {"type" => "string", "required" => false, "enum" => ["new", "in_progress", "completed"]},
      "processors" => {"type" => "string", "required" => false},
      "rights_determined" => {"type" => "boolean", "default" => false},
      
      "linked_records" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {"type" => [{"type" => "JSONModel(:accession) uri"},
                                 {"type" => "JSONModel(:resource) uri"},
                                 {"type" => "JSONModel(:digital_object) uri"}],
              "ifmissing" => "error"}
          }
        }
      }
    },

    "additionalProperties" => false
  }
}
