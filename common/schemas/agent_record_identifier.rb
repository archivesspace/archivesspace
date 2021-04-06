{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "primary_identifier" => {"type" => "boolean", "ifmissing" => "error"},
      "record_identifier" => {
        "type" => "string",
        "maxLength" => 65000,
        "ifmissing" => "error"
      },
      "source" => {
        "type" => "string",
        "dynamic_enum" => "name_source",
        "ifmissing" => "error"
      },
      "identifier_type" => {
        "type" => "string",
        "dynamic_enum" => "identifier_type",
        "required" => false
      },
    }
  }
}
