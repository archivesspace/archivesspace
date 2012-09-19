{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "primary_name" => {"type" => "string", "ifmissing" => "error"},
      "subordinate_name_1" => {"type" => "string"},
      "subordinate_name_2" => {"type" => "string"},
      "number" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
