{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "software_name" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error"},
      "version" => {"type" => "string", "maxLength" => 32672},
      "manufacturer" => {"type" => "string", "maxLength" => 32672},
    },

    "additionalProperties" => false,
  },
}
