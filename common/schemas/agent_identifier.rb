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
      "identifier_type" => {
        "type" => "string",
        "dynamic_enum" => "identifier_type",
        "required" => false
      },
      "require_record" => {
        "type" => "boolean",
        "default" => true,
      }
    }
  }
}
