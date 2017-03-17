{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "negated" => {"type" => "boolean", "default" => false},
      "field" => {"type" => "string", "ifmissing" => "error"},
      "value" => {"type" => "string"},

      "literal" => {"type" => "boolean", "default" => false},
      "comparator" => {"type" => "string", "enum" => ["contains", "empty"]},

    },
  },
}
