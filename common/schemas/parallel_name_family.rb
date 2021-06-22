{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "parent" => "abstract_parallel_name",
    "type" => "object",

    "properties" => {
      "family_name" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error"},
      "prefix" => {"type" => "string", "maxLength" => 65000},
      "location" => {"type" => "string", "maxLength" => 65000},
      "family_type" => {"type" => "string", "maxLength" => 65000}
    },
  },
}
