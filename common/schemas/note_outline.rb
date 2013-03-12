{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {

      "publish" => {"type" => "boolean", "default" => true},
      "internal" => {"type" => "boolean", "default" => false},

      "content" => {"type" => "string", "ifmissing" => "error"},

    },

    "additionalProperties" => false,
  },
}
