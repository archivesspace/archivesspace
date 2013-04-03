{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error", "minLength" => 1},
      "location" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "default" => ""},
      "publish" => {"type" => "boolean", "default" => true},
    },

    "additionalProperties" => false,
  },
}
