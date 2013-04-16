{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
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
