{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "entity_identifier" => {
        "type" => "string", 
        "maxLength" => 65000, 
        "ifmissing" => "error"
      },
      "identifier_type_enum" => {
        "type" => "string",
        "dynamic_enum" => "identifier_type_enum",
        "required" => false
      },
      "agent_person_id"           => {"type" => "integer", "required" => false},
      "agent_family_id"           => {"type" => "integer", "required" => false},
      "agent_corporate_entity_id" => {"type" => "integer", "required" => false},
      "agent_software_id"         => {"type" => "integer", "required" => false}
    }
  }
}
