{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/config/enumeration_values",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "value" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "position" => {"type" => "integer" },
      "suppressed" => {"type" => "boolean" }
    }
  }
}
