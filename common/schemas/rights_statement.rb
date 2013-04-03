{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "rights_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["intellectual_property", "license", "statute", "institutional_policy"]},
      "identifier" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "required" => false},

      "active" => {"type" => "boolean", "default" => true},

      "materials" => {"type" => "string", "maxLength" => 255, "required" => false},

      "ip_status" => {"type" => "string", "required" => false, "enum" => ["copyrighted", "public_domain", "unknown"]},
      "ip_expiration_date" => {"type" => "date", "required" => false},

      "license_identifier_terms" => {"type" => "string", "maxLength" => 255, "required" => false},

      "statute_citation" => {"type" => "string", "maxLength" => 255, "required" => false},

      "jurisdiction" => {"type" => "string", "required" => false, "enum" => ["AF", "AX", "AL", "DZ", "AS", "AD", "AO", "AI", "AQ", "AG", "AR", "AM", "AW", "AU", "AT", "AZ", "BS", "BH", "BD", "BB", "BY", "BE", "BZ", "BJ", "BM", "BT", "BO", "BQ", "BA", "BW", "BV", "BR", "IO", "BN", "BG", "BF", "BI", "KH", "CM", "CA", "CV", "KY", "CF", "TD", "CL", "CN", "CX", "CC", "CO", "KM", "CG", "CD", "CK", "CR", "CI", "HR", "CU", "CW", "CY", "CZ", "DK", "DJ", "DM", "DO", "EC", "EG", "SV", "GQ", "ER", "EE", "ET", "FK", "FO", "FJ", "FI", "FR", "GF", "PF", "TF", "GA", "GM", "GE", "DE", "GH", "GI", "GR", "GL", "GD", "GP", "GU", "GT", "GG", "GN", "GW", "GY", "HT", "HM", "VA", "HN", "HK", "HU", "IS", "IN", "ID", "IR", "IQ", "IE", "IM", "IL", "IT", "JM", "JP", "JE", "JO", "KZ", "KE", "KI", "KP", "KR", "KW", "KG", "LA", "LV", "LB", "LS", "LR", "LY", "LI", "LT", "LU", "MO", "MK", "MG", "MW", "MY", "MV", "ML", "MT", "MH", "MQ", "MR", "MU", "YT", "MX", "FM", "MD", "MC", "MN", "ME", "MS", "MA", "MZ", "MM", "NA", "NR", "NP", "NL", "NC", "NZ", "NI", "NE", "NG", "NU", "NF", "MP", "NO", "OM", "PK", "PW", "PS", "PA", "PG", "PY", "PE", "PH", "PN", "PL", "PT", "PR", "QA", "RE", "RO", "RU", "RW", "BL", "SH", "KN", "LC", "MF", "PM", "VC", "WS", "SM", "ST", "SA", "SN", "RS", "SC", "SL", "SG", "SX", "SK", "SI", "SB", "SO", "ZA", "GS", "SS", "ES", "LK", "SD", "SR", "SJ", "SZ", "SE", "CH", "SY", "TW", "TJ", "TZ", "TH", "TL", "TG", "TK", "TO", "TT", "TN", "TR", "TM", "TC", "TV", "UG", "UA", "AE", "GB", "US", "UM", "UY", "UZ", "VU", "VE", "VN", "VG", "VI", "WF", "EH", "YE", "ZM", "ZW"]},
      "type_note" => {"type" => "string", "maxLength" => 255, "required" => false},

      "permissions" => {"type" => "string", "maxLength" => 32672, "required" => false},
      "restrictions" => {"type" => "string", "maxLength" => 32672, "required" => false},
      "restriction_start_date" => {"type" => "date", "required" => false},
      "restriction_end_date" => {"type" => "date", "required" => false},

      "granted_note" => {"type" => "string", "maxLength" => 255, "required" => false},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
    },

    "additionalProperties" => false,
  },
}
