{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "agent_type" => {
        "type" => "string",
        "required" => false,
        "enum" => ["agent_person", "agent_corporate_entity", "agent_software", "agent_family"]
      },

      "agent_contacts" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_contact) object"}
      },

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

    },
  },
}
