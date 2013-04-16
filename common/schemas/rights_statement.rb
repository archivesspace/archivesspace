{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "rights_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "rights_statement_rights_type"},
      "identifier" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "required" => false},

      "active" => {"type" => "boolean", "default" => true},

      "materials" => {"type" => "string", "maxLength" => 255, "required" => false},

      "ip_status" => {"type" => "string", "required" => false, "dynamic_enum" => "rights_statement_ip_status"},
      "ip_expiration_date" => {"type" => "date", "required" => false},

      "license_identifier_terms" => {"type" => "string", "maxLength" => 255, "required" => false},

      "statute_citation" => {"type" => "string", "maxLength" => 255, "required" => false},

      "jurisdiction" => {"type" => "string", "required" => false, "dynamic_enum" => "country_iso_3166"},
      "type_note" => {"type" => "string", "maxLength" => 255, "required" => false},

      "permissions" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "restrictions" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "restriction_start_date" => {"type" => "date", "required" => false},
      "restriction_end_date" => {"type" => "date", "required" => false},

      "granted_note" => {"type" => "string", "maxLength" => 255, "required" => false},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
    },

    "additionalProperties" => false,
  },
}
