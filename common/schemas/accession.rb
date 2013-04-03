{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/accessions",
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

      "title" => {"type" => "string", "maxLength" => 32672, "minLength" => 1, "ifmissing" => "error"},

      "id_0" => {"type" => "string", "ifmissing" => "error", "maxLength" => 255},
      "id_1" => {"type" => "string", "maxLength" => 255},
      "id_2" => {"type" => "string", "maxLength" => 255},
      "id_3" => {"type" => "string", "maxLength" => 255},

      "content_description" => {"type" => "string", "maxLength" => 32672},
      "condition_description" => {"type" => "string", "maxLength" => 32672},
      
      "disposition" => {"type" => "string", "maxLength" => 32672},
      "inventory" => {"type" => "string", "maxLength" => 32672},
      
      "provenance" => {"type" => "string", "maxLength" => 32672},

      "accession_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
      
      "publish" => {"type" => "boolean", "default" => false},

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

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
      "rights_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},
      "collection_management" => {"type" => "JSONModel(:collection_management) object"},

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

      "suppressed" => {"type" => "boolean"},

      "acquisition_type" => {"type" => "string", "dynamic_enum" => "accession_acquisition_type"},
      
      "resource_type" => {"type" => "string", "dynamic_enum" => "accession_resource_type"},
      
      "restrictions_apply" => {"type" => "boolean", "default" => false},

      "retention_rule" => {"type" => "string", "maxLength" => 32672},
      
      "general_note" => {"type" => "string", "maxLength" => 32672},
      
      "access_restrictions" => {"type" => "boolean", "default" => false},
      "access_restrictions_note" => {"type" => "string", "maxLength" => 32672},
      
      "use_restrictions" => {"type" => "boolean", "default" => false},
      "use_restrictions_note" => {"type" => "string", "maxLength" => 32672},

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "enum" => ['creator', 'source', 'subject'],
              "ifmissing" => "error"
            },

            "relator" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_archival_record_relators",
            },

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

    },

    "additionalProperties" => false,
  },
}
