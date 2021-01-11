{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "date_role" => {"type" => "string", "dynamic_enum" => "date_role", "ifmissing" => "error" },

      "date_expression" => {"type" => "string", "maxLength" => 255},
      "date_standardized" => {"type" => "string", "maxLength" => 255},
      "date_standardized_type" => {"type" => "string", "dynamic_enum" => "date_standardized_type", "required" => "false"}
    }
  }
}
