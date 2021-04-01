{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "agency_code_type" => {
          "type" => "string",
          "dynamic_enum" => "agency_code_type",
          "required" => false
      },
      "maintenance_agency" => {
          "type" => "string",
          "maxLength" => 65000,
          "ifmissing" => "error",
      },
    }
  }
}
