{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "family_name" => {"type" => "string", "ifmissing" => "error"},
    },

    "additionalProperties" => false,
  },
}
