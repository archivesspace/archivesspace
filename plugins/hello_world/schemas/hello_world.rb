{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/hello_world",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "who" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "default" => ""},
    },

    "additionalProperties" => false,
  },
}
