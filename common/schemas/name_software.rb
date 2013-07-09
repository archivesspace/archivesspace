{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "software_name" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error"},
      "version" => {"type" => "string", "maxLength" => 65000},
      "manufacturer" => {"type" => "string", "maxLength" => 65000},
    },
  },
}
