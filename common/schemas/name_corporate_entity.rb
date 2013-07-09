{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "primary_name" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error"},
      "subordinate_name_1" => {"type" => "string", "maxLength" => 65000},
      "subordinate_name_2" => {"type" => "string", "maxLength" => 65000},
      "number" => {"type" => "string", "maxLength" => 255},
    },
  },
}
