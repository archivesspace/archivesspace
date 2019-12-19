{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "field" => {"type" => "string", "ifmissing" => "error"},
      "relator" => {"type" => "string"},
      "value" => {"type" => "string"},
    },
  },
}
