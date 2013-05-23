{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "default" => ""},
    },

    "additionalProperties" => false,
  },
}
