{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "name" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error"},
      "salutation" => {"type" => "string", "dynamic_enum" => "agent_contact_salutation"},
      "address_1" => {"type" => "string", "maxLength" => 65000},
      "address_2" => {"type" => "string", "maxLength" => 65000},
      "address_3" => {"type" => "string", "maxLength" => 65000},
      "city" => {"type" => "string", "maxLength" => 65000},
      "region" => {"type" => "string", "maxLength" => 65000},
      "country" => {"type" => "string", "maxLength" => 65000},
      "post_code" => {"type" => "string", "maxLength" => 65000},
      "telephones" =>{
        "type" => "array",
        "items" => {"type" => "JSONModel(:telephone) object"}
      },
      "fax" => {"type" => "string", "maxLength" => 65000},
      "email" => {"type" => "string", "maxLength" => 65000},
      "email_signature" => {"type" => "string", "maxLength" => 65000},
      "note" => {"type" => "string", "maxLength" => 65000},
    },
  },
}
