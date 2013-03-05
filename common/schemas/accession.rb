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
            "external_id" => {"type" => "string"},
            "source" => {"type" => "string"},
          }
        }
      },

      "title" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},

      "id_0" => {"type" => "string", "ifmissing" => "error"},
      "id_1" => {"type" => "string"},
      "id_2" => {"type" => "string"},
      "id_3" => {"type" => "string"},

      "content_description" => {"type" => "string"},
      "condition_description" => {"type" => "string"},
      
      "disposition" => {"type" => "string"},
      "inventory" => {"type" => "string"},
      
      "provenance" => {"type" => "string"},

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

      "retention_rule" => {"type" => "string"},
      
      "general_note" => {"type" => "string"},
      
      "access_restrictions" => {"type" => "boolean", "default" => false},
      "access_restrictions_note" => {"type" => "string"},
      
      "use_restrictions" => {"type" => "boolean", "default" => false},
      "use_restrictions_note" => {"type" => "string"},

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_archival_record_roles",
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
