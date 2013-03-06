{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "field" => {"type" => "string", "ifmissing" => "error"},
      "value" => {"type" => "string", "ifmissing" => "error"},

    },

    "additionalProperties" => false,
  },
}
