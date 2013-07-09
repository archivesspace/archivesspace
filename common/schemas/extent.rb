{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "portion" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "extent_portion"},
      "number" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},
      "extent_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "extent_extent_type"},

      "container_summary" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "physical_details" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "dimensions" => {"type" => "string", "maxLength" => 255, "required" => false},
    },
  },
}
