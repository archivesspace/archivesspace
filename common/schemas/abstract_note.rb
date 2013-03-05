{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "label" => {"type" => "string"},
      "content" => {
        "type" => "array",
        "items" => {"type" => "string"},
        "minItems" => 1,
        "ifmissing" => "error",
      },
      "publish" => {"type" => "boolean", "default" => true},
      "internal" => {"type" => "boolean", "default" => false},
      "persistent_id" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
