{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "family_name" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error"},
      "prefix" => {"type" => "string", "maxLength" => 32672},
    },

    "additionalProperties" => false,
  },
}
