{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/config/enumerations/migration",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "enum_uri" => {"type" => "JSONModel(:enumeration) uri", "ifmissing" => "error"},
      "from" => {"type" => "string", "ifmissing" => "error"},
      "to" => {"type" => "string", "ifmissing" => "error"},
    },
  },
}
