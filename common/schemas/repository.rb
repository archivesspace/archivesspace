{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "repo_code" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "default" => ""},
      "org_code" => {"type" => "string", "maxLength" => 255},
      "parent_institution_name" => {"type" => "string", "maxLength" => 255},
      "address_1" => {"type" => "string", "maxLength" => 255},
      "address_2" => {"type" => "string", "maxLength" => 255},
      "city" => {"type" => "string", "maxLength" => 255},
      "district" => {"type" => "string", "maxLength" => 255},
      "country" => {"type" => "string", "required" => false, "dynamic_enum" => "country_iso_3166"},
      "post_code" => {"type" => "string", "maxLength" => 255},
      "telephone" => {"type" => "string", "maxLength" => 255},
      "fax" => {"type" => "string", "maxLength" => 255},
      "email" => {"type" => "string", "maxLength" => 255},
      "email_signature" => {"type" => "string", "maxLength" => 255},
      "url" => {"type" => "string", "maxLength" => 255, "pattern" => "\\Ahttps?:\\/\\/[\\\S]+\\z"},
      "image_url" => {"type" => "string", "maxLength" => 255, "pattern" => "\\Ahttps?:\\/\\/[\\\S]+\\z"},
      "contact_persons" => {"type" => "string", "maxLength" => 65000},
      
    },

    "additionalProperties" => false,
  },
}
