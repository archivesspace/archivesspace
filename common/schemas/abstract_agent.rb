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

      "agent_record_controls" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_record_control) object"}
      },

      "agent_alternate_sets" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_alternate_set) object"}
      },

      "agent_conventions_declarations" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_conventions_declaration) object"}
      },

      "agent_other_agency_codes" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_other_agency_codes) object"}
      },

      "agent_maintenance_histories" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_maintenance_history) object"}
      },

      "agent_record_identifiers" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_record_identifier) object"}
      },

      "agent_identifiers" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_identifier) object"}
      },
 
      "agent_sources" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_sources) object"}
      },

      "agent_places" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_place) object"}
      },

      "agent_occupations" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_occupation) object"}
      },

      "agent_functions" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_function) object"}
      },
      
      "agent_topics" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_topic) object"}
      },

      "agent_resources" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_resource) object"}
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
                               {"type" => "JSONModel(:note_mandate) object"},
                               {"type" => "JSONModel(:note_legal_status) object"},
                               {"type" => "JSONModel(:note_structure_or_genealogy) object"},
                               {"type" => "JSONModel(:note_general_context) object"}]},
      },

      "used_within_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},
      "used_within_published_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},

      "dates_of_existence" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:structured_date_label) object"}
      },
      
      "used_languages" => {"type" => "array", "items" => {"type" => "JSONModel(:used_language) object"}},

      "publish" => {"type" => "boolean"},

      "is_user" => {"readonly" => true, "type" => "string"},

    },
  },
}
