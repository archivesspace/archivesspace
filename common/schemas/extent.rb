{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "portion" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "default" => "whole", "enum" => ["whole", "part"]},
      "number" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},
      "extent_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "extent_extent_type"},

      "container_summary" => {"type" => "string", "maxLength" => 255, "required" => false},
      "physical_details" => {"type" => "string", "maxLength" => 255, "required" => false},
      "dimensions" => {"type" => "string", "maxLength" => 255, "required" => false},
    },

    "additionalProperties" => false,
  },
}
