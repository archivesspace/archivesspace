{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "field" => {"type" => "string", "ifmissing" => "error"},
      "from" => {"type" => "string"},
      "to" => {"type" => "string"},

    },
  },
}
