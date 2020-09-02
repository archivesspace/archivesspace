{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "agency_code_type_enum" => {
          "type" => "string",
          "dynamic_enum" => "agency_code_type_enum",
          "required" => false
      },
      "maintenance_agency" => {
          "type" => "string", 
          "maxLength" => 65000, 
          "required" => true,
          "ifmissing" => "error",
      },
    }
  }
}
