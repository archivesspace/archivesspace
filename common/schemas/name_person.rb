{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "parent" => "abstract_name",
    "type" => "object",

    "properties" => {
      "primary_name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "title" => {"type" => "string", "maxLength" => 32672},
      "name_order" => {
        "type" => "string",
        "ifmissing" => "error",
        "default" => "inverted",
        "enum" => ["inverted", "direct"]
      },
      "prefix" => {"type" => "string", "maxLength" => 32672},
      "rest_of_name" => {"type" => "string", "maxLength" => 32672},
      "suffix" => {"type" => "string", "maxLength" => 32672},
      "fuller_form" => {"type" => "string", "maxLength" => 32672},
      "number" => {"type" => "string", "maxLength" => 255},
    },

    "additionalProperties" => false,
  },
}
