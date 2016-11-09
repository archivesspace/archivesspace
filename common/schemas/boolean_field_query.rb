{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "field" => {"type" => "string", "ifmissing" => "error"},
      "value" => {"type" => "boolean", "ifmissing" => "error", "default" => true},
      "negated" => {"type" => "boolean", "default" => false},

    },
  },
}
