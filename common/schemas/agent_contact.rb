{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "name" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error"},
      "salutation" => {"type" => "string", "dynamic_enum" => "agent_contact_salutation"},
      "address_1" => {"type" => "string", "maxLength" => 32672},
      "address_2" => {"type" => "string", "maxLength" => 32672},
      "address_3" => {"type" => "string", "maxLength" => 32672},
      "city" => {"type" => "string", "maxLength" => 32672},
      "region" => {"type" => "string", "maxLength" => 32672},
      "country" => {"type" => "string", "maxLength" => 32672},
      "post_code" => {"type" => "string", "maxLength" => 32672},
      "telephone" => {"type" => "string", "maxLength" => 32672},
      "telephone_ext" => {"type" => "string", "maxLength" => 32672},
      "fax" => {"type" => "string", "maxLength" => 32672},
      "email" => {"type" => "string", "maxLength" => 32672},
      "note" => {"type" => "string", "maxLength" => 32672},
    },

    "additionalProperties" => false,
  },
}
