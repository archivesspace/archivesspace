{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "begin_date_expression" => {"type" => "string", "maxLength" => 255},
      "begin_date_standardized" => {"type" => "string", "maxLength" => 255},
      "begin_date_standardized_type_enum" => {"type" => "string", "dynamic_enum" => "date_standardized_type_enum", "required" => "false"},

      "end_date_expression" => {"type" => "string", "maxLength" => 255},
      "end_date_standardized" => {"type" => "string", "maxLength" => 255},
      "end_date_standardized_type_enum" => {"type" => "string", "dynamic_enum" => "date_standardized_type_enum", "required" => "false"}
    }
  }
}
