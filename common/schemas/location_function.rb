{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "location_function_type" => {"type" => "string", "dynamic_enum" => "location_function_type"},
    },
  },
}
