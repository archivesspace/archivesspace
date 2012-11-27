{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "ref_id" => {"type" => "string", "pattern" => "^[a-zA-Z0-9]*$"},
      "component_id" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9_]*$"},
      "title" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},

      "level" => {"type" => "string", "minLength" => 1, "required" => false},
      "parent" => {"type" => "JSONModel(:archival_object) uri", "required" => false},
      "resource" => {"type" => "JSONModel(:resource) uri", "required" => false},
      "position" => {"type" => "integer", "required" => false},

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
      "rights_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement) object"}},
      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},

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
                                 {"type" => "JSONModel(:agent_software) uri"}],
                      "ifmissing" => "error"}
          }
        }
      },

    },

    "additionalProperties" => false,
  },
}
