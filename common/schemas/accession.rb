{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/accessions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "title" => {"type" => "string", "maxLength" => 8192, "ifmissing" => nil},
      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},

      "id_0" => {"type" => "string", "ifmissing" => "error", "maxLength" => 255},
      "id_1" => {"type" => "string", "maxLength" => 255},
      "id_2" => {"type" => "string", "maxLength" => 255},
      "id_3" => {"type" => "string", "maxLength" => 255},

      "content_description" => {"type" => "string", "maxLength" => 65000},
      "condition_description" => {"type" => "string", "maxLength" => 65000},

      "disposition" => {"type" => "string", "maxLength" => 65000},
      "inventory" => {"type" => "string", "maxLength" => 65000},

      "provenance" => {"type" => "string", "maxLength" => 65000},

      "related_accessions" => {
        "type" => "array",
        "items" => {
          "type" => [
            {"type" => "JSONModel(:accession_parts_relationship) object"},
            {"type" => "JSONModel(:accession_sibling_relationship) object"}
          ]
        },
      },


      "accession_date" => {"type" => "date", "minLength" => 1, "default" => "9999-12-31"},

      "publish" => {"type" => "boolean"},
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

      "subjects" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:subject) uri",
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "linked_events" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:event) uri",
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
      "lang_materials" => {"type" => "array", "items" => {"type" => "JSONModel(:lang_material) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
      "rights_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},
      "collection_management" => {"type" => "JSONModel(:collection_management) object"},
      "user_defined" => {"type" => "JSONModel(:user_defined) object"},

      "related_resources" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:resource) uri"}],
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "component_links" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:archival_object) uri"}],
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "suppressed" => {"type" => "boolean", "readonly" => "true"},

      "acquisition_type" => {"type" => "string", "dynamic_enum" => "accession_acquisition_type"},

      "resource_type" => {"type" => "string", "dynamic_enum" => "accession_resource_type"},

      "language" => {"type" => "string", "dynamic_enum" => "language_iso639_2"},

      "script" => {"type" => "string", "dynamic_enum" => "script_iso15924"},

      "restrictions_apply" => {"type" => "boolean", "default" => false},

      "retention_rule" => {"type" => "string", "maxLength" => 65000},

      "general_note" => {"type" => "string", "maxLength" => 65000},

      "access_restrictions" => {"type" => "boolean", "default" => false},
      "access_restrictions_note" => {"type" => "string", "maxLength" => 65000},

      "use_restrictions" => {"type" => "boolean", "default" => false},
      "use_restrictions_note" => {"type" => "string", "maxLength" => 65000},

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_role",
              "ifmissing" => "error"
            },

            "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}},

            "title" => {"type" => "string"},

            "relator" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_archival_record_relators",
            },

            "is_primary" => {"type" => "boolean", "default" => false},

            "ref" => {"type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"},
                                 {"type" => "JSONModel(:agent_family) uri"},
                                 {"type" => "JSONModel(:agent_person) uri"},
                                 {"type" => "JSONModel(:agent_software) uri"}],
              "ifmissing" => "error"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},

      "metadata_rights_declarations" => {"type" => "array", "items" => {"type" => "JSONModel(:metadata_rights_declaration) object"}},

      "representative_file_version" => {
        "type" => "JSONModel(:file_version) object",
        "readonly" => true
      },
    },
  },
}
