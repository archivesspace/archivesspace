{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "rights_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "rights_statement_rights_type"},
      "identifier" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "required" => false},

      "status" => {"type" => "string", "required" => false, "dynamic_enum" => "rights_statement_ip_status"},
      "determination_date" => {"type" => "date", "required" => false},
      "start_date" => {"type" => "date", "required" => false},
      "end_date" => {"type" => "date", "required" => false},

      "license_terms" => {"type" => "string", "maxLength" => 255, "required" => false},

      "statute_citation" => {"type" => "string", "maxLength" => 255, "required" => false},
      "jurisdiction" => {"type" => "string", "required" => false, "dynamic_enum" => "country_iso_3166"},

      "other_rights_basis" => {"type" => "string", "required" => false, "dynamic_enum" => "rights_statement_other_rights_basis"},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement_external_document) object"}},
      "acts" => {"type" => "array", "items" => {"type" => "JSONModel(:rights_statement_act) object"}},
      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
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
      "notes" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:note_rights_statement) object"},
      },
    },
  },
}
