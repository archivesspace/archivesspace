{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/top_containers",

    "properties" => {

      "uri" => {"type" => "string", "required" => false},

      "indicator" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error" },
      "type" => {"type" => "string", "dynamic_enum" => "container_type", "required" => false},
      "barcode" => {"type" => "string", "maxLength" => 255},

      "display_string" => {"type" => "string", "readonly" => true},
      "long_display_string" => {"type" => "string", "readonly" => true},

      "subcontainer_barcodes" => {"type" => "string", "required" => false},

      "ils_holding_id" => {"type" => "string", "maxLength" => 255, "required" => false},
      "ils_item_id" => {"type" => "string", "maxLength" => 255, "required" => false},
      "exported_to_ils" => {"type" => "string", "required" => false},

      "restricted" => {
        "type" => "boolean",
        "readonly" => "true"
      },

      "created_for_collection" => {"type" => "string", "maxLength" => 255, "required" => false},

      "is_linked_to_published_record" => {"type" => "boolean", "readonly" => true},

      "active_restrictions" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {"type" => "JSONModel(:rights_restriction) object"},
      },


      "container_locations" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:container_location) object",
        }
      },

      "container_profile" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:container_profile) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "series" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:archival_object) uri",
            },
            "display_string" => {"type" => "string"},
            "identifier" => {"type" => "string"},
            "level_display_string" => {"type" => "string"},
            "publish" => {"type" => "boolean"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "collection" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [
                {"type" => "JSONModel(:resource) uri"},
                {"type" => "JSONModel(:accession) uri"}
              ]
            },
            "display_string" => {"type" => "string"},
            "identifier" => {"type" => "string"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      }
    }
  }
}
