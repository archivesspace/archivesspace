# Schema inherits from the abstract_archival_object schema, and must only include extensions/overrides unique to resource records.

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/resources",
    "properties" => {

      "id_0" => {"type" => "string", "ifmissing" => "error", "maxLength" => 255},
      "id_1" => {"type" => "string", "maxLength" => 255},
      "id_2" => {"type" => "string", "maxLength" => 255},
      "id_3" => {"type" => "string", "maxLength" => 255},
      "external_ark_url" => {"type" => "string", "required" => false},

      "import_current_ark" => {"type" => "string"},

      "import_previous_arks" => {
        "type" => "array",
        "items" => {
          "type" => "string",
        }
      },

      "level" => {"type" => "string", "ifmissing" => "error", "dynamic_enum" => "archival_record_level"},
      "other_level" => {"type" => "string", "maxLength" => 255},

      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},

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

      "restrictions" => {"type" => "boolean", "default" => false},

      "repository_processing_note" => {"type" => "string", "maxLength" => 65000},

      "ead_id" => {"type" => "string", "maxLength" => 255},
      "ead_location" => {"type" => "string", "maxLength" => 255},

      # Finding aid
      "finding_aid_title" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_subtitle" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_filing_title" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_date" => {"type" => "string", "maxLength" => 255},
      "finding_aid_author" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_description_rules" => {"type" => "string", "dynamic_enum" => "resource_finding_aid_description_rules"},
      "finding_aid_language" => {"type" => "string", "dynamic_enum" => "language_iso639_2", "ifmissing" => "error"},
      "finding_aid_script" => {"type" => "string", "dynamic_enum" => "script_iso15924", "ifmissing" => "error"},
      "finding_aid_language_note" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_sponsor" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_edition_statement" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_series_statement" => {"type" => "string", "maxLength" => 65000},
      "finding_aid_status" => {"type" => "string", "dynamic_enum" => "resource_finding_aid_status"},
      "is_finding_aid_status_published" => {"type" => "boolean", "default" => true},
      "finding_aid_note" => {"type" => "string", "maxLength" => 65000},

      # Languages (overrides abstract schema)
      "lang_materials" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:lang_material) object"}},

      # Extents (overrides abstract schema)
      "extents" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:extent) object"}},

      "revision_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:revision_statement) object"}},

      # Dates (overrides abstract schema)
      "dates" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:date) object"}},

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},
      "collection_management" => {"type" => "JSONModel(:collection_management) object"},
      "user_defined" => {"type" => "JSONModel(:user_defined) object"},

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

      "classifications" => {
              "type" => "array",
              "items" => {
                "type" => "object",
                "subtype" => "ref",
                "properties" => {
                  "ref" => {
                    "type" => [ { "type" => "JSONModel(:classification) uri"},
                                { "type" => "JSONModel(:classification_term) uri" }],
                    "ifmissing" => "error"
                  },
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

      "ark_name" => {
        "type" => "JSONModel(:ark_name) object",
        "readonly" => true,
        "required" => false
      },
      "metadata_rights_declarations" => {"type" => "array", "items" => {"type" => "JSONModel(:metadata_rights_declaration) object"}},
    },
  },
}
