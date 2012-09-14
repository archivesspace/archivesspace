{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "software_name" => {"type" => "string", "ifmissing" => "error"},
      "version" => {"type" => "string"},
      "manufacturer" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
