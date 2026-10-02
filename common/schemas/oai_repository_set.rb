{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "set_name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "set_description" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error", "minLength" => 1},
      "repo_codes" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 255},
        "minItems" => 1,
        "ifmissing" => "error",
      },
    },
  },
}
