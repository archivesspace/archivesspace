{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "name" => {"type" => "string", "ifmissing" => "error"},
      "salutation" => {"type" => "string", "dynamic_enum" => "agent_contact_salutation"},
      "address_1" => {"type" => "string"},
      "address_2" => {"type" => "string"},
      "address_3" => {"type" => "string"},
      "city" => {"type" => "string"},
      "region" => {"type" => "string"},
      "country" => {"type" => "string"},
      "post_code" => {"type" => "string"},
      "telephone" => {"type" => "string"},
      "telephone_ext" => {"type" => "string"},
      "fax" => {"type" => "string"},
      "email" => {"type" => "string"},
      "note" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
