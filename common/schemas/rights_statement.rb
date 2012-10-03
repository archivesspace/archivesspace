{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "rights_type" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["intellectual_property", "license", "statute", "institutional_policy"]},
      "identifier" => {"type" => "string", "minLength" => 1, "required" => true},

      "materials" => {"type" => "string", "required" => false},

      "ip_status" => {"type" => "string", "required" => false, "enum" => ["copyrighted", "public_domain", "unknown"]},
      "ip_expiration_date" => {"type" => "date", "required" => false},

      "license_identifier_terms" => {"type" => "string", "required" => false},

      "statute_citation" => {"type" => "string", "required" => false},

      "jurisdiction" => {"type" => "string", "required" => false},
      "type_note" => {"type" => "string", "required" => false},

      "permissions" => {"type" => "string", "required" => false},
      "restrictions" => {"type" => "string", "required" => false},
      "restriction_start_date" => {"type" => "date", "required" => false},
      "restriction_end_date" => {"type" => "date", "required" => false},

      "granted_note" => {"type" => "string", "required" => false},
    },

    "additionalProperties" => false,
  },
}
