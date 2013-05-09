{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "label" => {"type" => "string", "maxLength" => 65000},
      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000},
        "minItems" => 1,
        "ifmissing" => "error",
      },
      "publish" => {"type" => "boolean", "default" => true},
      "persistent_id" => {"type" => "string", "maxLength" => 255},
    },

    "additionalProperties" => false,
  },
}
