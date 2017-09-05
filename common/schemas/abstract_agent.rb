{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {
        "type" => "string",
        "readonly" => true
      },

      "is_linked_to_published_record" => {"type" => "boolean", "readonly" => true},

      "agent_type" => {
        "type" => "string",
        "required" => false,
        "enum" => ["agent_person", "agent_corporate_entity", "agent_software", "agent_family", "user"]
      },

      "agent_contacts" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_contact) object"}
      },

      "linked_agent_roles" => {
        "type" => "array",
        "items" => {"type" => "string"},
        "readonly" => true
      },

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

      "system_generated" => {
        "readonly" => true,
        "type" => "boolean"
      },

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bioghist) object"},
                               {"type" => "JSONModel(:note_agent_rights_statement) object"}]},
      },

      "used_within_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},
      "used_within_published_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},

      "dates_of_existence" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},

      "publish" => {"type" => "boolean"},

      "is_user" => {"readonly" => true, "type" => "string"},

    },
  },
}
