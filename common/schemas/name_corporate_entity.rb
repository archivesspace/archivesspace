{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "primary_name" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error"},
      "subordinate_name_1" => {"type" => "string", "maxLength" => 32672},
      "subordinate_name_2" => {"type" => "string", "maxLength" => 32672},
      "number" => {"type" => "string", "maxLength" => 255},
    },

    "additionalProperties" => false,
  },
}
