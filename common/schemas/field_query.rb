{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "negated" => {"type" => "boolean", "default" => false},
      "field" => {"type" => "string", "enum" => ["fullrecord", "title", "creator"], "ifmissing" => "error"},
      "value" => {"type" => "string", "ifmissing" => "error"},

    },

    "additionalProperties" => false,
  },
}
