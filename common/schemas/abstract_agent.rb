{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
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


      "related_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:agent_person) uri"},
                         {"type" => "JSONModel(:agent_family) uri"},
                         {"type" => "JSONModel(:agent_corporate_entity) uri"},
                         {"type" => "JSONModel(:agent_software) uri"}],
              "ifmissing" => "error"
            },

            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },



      "agent_type" => {
        "type" => "string",
        "required" => false,
        "enum" => ["agent_person", "agent_corporate_entity", "agent_software", "agent_family", "user"]
      },

      "agent_contacts" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_contact) object"}
      },

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bioghist) object"}]},
      },

    },
  },
}
