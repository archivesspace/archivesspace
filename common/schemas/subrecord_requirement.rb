{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "property" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "record_type" => {
        "type" => "string"
      },
      "required_fields" => {
        "type" => "array",
        "items" => {"type" => "string"},
      },
      "required" => {"type" => "boolean", "default" => false}
    },
  },
}
