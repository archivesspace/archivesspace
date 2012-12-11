{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
      "location" => {"type" => "string", "ifmissing" => "error", "default" => ""},
      "publish" => {"type" => "boolean", "default" => true},
    },

    "additionalProperties" => false,
  },
}
