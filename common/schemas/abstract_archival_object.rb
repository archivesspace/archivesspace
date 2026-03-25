# This is the parent schema for the four primary archival record types: resources, archival objects, digital objects, and digital object components.

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},

      "publish" => {"type" => "boolean"},

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

      "linked_events" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:event) uri",
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
      "lang_materials" => {"type" => "array", "items" => {"type" => "JSONModel(:lang_material) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
      "rights_statements" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement) object"}},
      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_role",
              "ifmissing" => "error",
            },

            "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}},

            "relator" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_archival_record_relators",
            },

            "title" => {"type" => "string"},

            "ref" => {"type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"},
                                 {"type" => "JSONModel(:agent_family) uri"},
                                 {"type" => "JSONModel(:agent_person) uri"},
                                 {"type" => "JSONModel(:agent_software) uri"}],
              "ifmissing" => "error"},

            "is_primary" => {"type" => "boolean", "default" => false},

            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },
      "suppressed" => {"type" => "boolean", "readonly" => "true"},
      "representative_file_version" => {
        "type" => "JSONModel(:file_version) object",
        "readonly" => true
      },
    },
  },
}
