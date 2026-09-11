{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "set_name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "set_description" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error", "minLength" => 1},
      "sponsor_names" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000},
        "minItems" => 1,
        "ifmissing" => "error",
      },
    },
  },
}
