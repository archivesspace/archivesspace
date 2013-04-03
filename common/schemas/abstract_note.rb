{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "label" => {"type" => "string", "maxLength" => 32672},
      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 32672},
        "minItems" => 1,
        "ifmissing" => "error",
      },
      "publish" => {"type" => "boolean", "default" => true},
      "internal" => {"type" => "boolean", "default" => false},
      "persistent_id" => {"type" => "string", "maxLength" => 255},
    },

    "additionalProperties" => false,
  },
}
