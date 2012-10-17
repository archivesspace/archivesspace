{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "label" => {"type" => "string", "ifmissing" => "error"},
      "content" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "persistent_id" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
