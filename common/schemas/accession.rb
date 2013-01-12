{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/accessions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false, "readonly" => true},

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

      "content_description" => {"type" => "string", "ifmissing" => "warn"},
      "condition_description" => {"type" => "string", "ifmissing" => "warn"},

      "accession_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},

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

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "enum" => ["creator", "source", "subject"],
              "ifmissing" => "error"
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
