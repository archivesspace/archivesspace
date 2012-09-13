{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "primary_name" => {"type" => "string", "ifmissing" => "error"},
      "title" => {"type" => "string", "ifmissing" => "error"},
      "prefix" => {"type" => "string"},
      "rest_of_name" => {"type" => "string"},
      "suffix" => {"type" => "string"},
      "fuller_form" => {"type" => "string"},
      "number" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
