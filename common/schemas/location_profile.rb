{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/location_profiles",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "name" => {"type" => "string", "ifmissing" => "error"},

      "display_string" => {"type" => "string", "readonly" => true},

      "dimension_units" => {"type" => "string", "dynamic_enum" => "dimension_units"},

      "height" => {"type" => "string", "required" => false},
      "width" => {"type" => "string", "required" => false},
      "depth" => {"type" => "string", "required" => false},
    },
  },
}
