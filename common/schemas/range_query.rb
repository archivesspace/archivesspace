{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "negated" => {"type" => "boolean", "default" => false},

      "field" => {"type" => "string", "ifmissing" => "error"},
      "from" => {"type" => "string"},
      "to" => {"type" => "string"},

    },
  },
}
