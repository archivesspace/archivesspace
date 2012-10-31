{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/resources",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "id_0" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9 ]*$"},

      "title" => {"type" => "string", "minLength" => 1, "required" => true},

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
      "extents" => {"type" => "array", "required" => true, "minItems" => 1, "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
      "rights_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement) object"}},
      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "role" => {
              "type" => "string",
              "enum" => ["creator", "source", "subject"],
            },

            "ref" => {"type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"},
                                 {"type" => "JSONModel(:agent_family) uri"},
                                 {"type" => "JSONModel(:agent_person) uri"},
                                 {"type" => "JSONModel(:agent_software) uri"}]}
          }
        }
      },

    },

    "additionalProperties" => false,
  },
}
