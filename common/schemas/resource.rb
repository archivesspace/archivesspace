{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/resources",
    "properties" => {

      "id_0" => {"type" => "string", "ifmissing" => "error", "maxLength" => 255},
      "id_1" => {"type" => "string", "maxLength" => 255},
      "id_2" => {"type" => "string", "maxLength" => 255},
      "id_3" => {"type" => "string", "maxLength" => 255},

      "level" => {"type" => "string", "ifmissing" => "error", "enum" => ["class", "collection", "file", "fonds", "item", "otherlevel", "recordgrp", "series", "subfonds", "subgrp", "subseries"]},
      "other_level" => {"type" => "string", "maxLength" => 255},

      "language" => {"ifmissing" => "error"},

      "resource_type" => {"type" => "string", "dynamic_enum" => "resource_resource_type"},
      "tree" => {
          "type" => "object", 
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:resource_tree) uri",
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
      },


      "publish" => {"type" => "boolean", "default" => true},
      "restrictions" => {"type" => "boolean", "default" => false},

      "repository_processing_note" => {"type" => "string", "maxLength" => 32672},
      "container_summary" => {"type" => "string", "maxLength" => 32672},

      "ead_id" => {"type" => "string", "maxLength" => 255},
      "ead_location" => {"type" => "string", "maxLength" => 255},

      # Finding aid
      "finding_aid_title" => {"type" => "string", "maxLength" => 32672},
      "finding_aid_filing_title" => {"type" => "string", "maxLength" => 32672},
      "finding_aid_date" => {"type" => "string", "maxLength" => 255},
      "finding_aid_author" => {"type" => "string", "maxLength" => 255},
      "finding_aid_description_rules" => {"type" => "string", "dynamic_enum" => "resource_finding_aid_description_rules"},
      "finding_aid_language" => {"type" => "string", "maxLength" => 255},
      "finding_aid_sponsor" => {"type" => "string", "maxLength" => 255},
      "finding_aid_edition_statement" => {"type" => "string", "maxLength" => 32672},
      "finding_aid_series_statement" => {"type" => "string", "maxLength" => 32672},
      "finding_aid_revision_date" => {"type" => "string", "maxLength" => 255},
      "finding_aid_revision_description" => {"type" => "string", "maxLength" => 32672},
      "finding_aid_status" => {"type" => "string", "dynamic_enum" => "resource_finding_aid_status"},
      "finding_aid_note" => {"type" => "string", "maxLength" => 32672},

      # Extents (overrides abstract schema)
      "extents" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:extent) object"}},

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},
      "collection_management" => {"type" => "JSONModel(:collection_management) object"},

      "related_accessions" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {"type" => [{"type" => "JSONModel(:accession) uri"}],
                      "ifmissing" => "error"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },


      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },

    },

    "additionalProperties" => false,
  },
}
