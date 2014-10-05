{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "relator" => {
        "type" => "string",
        "dynamic_enum" => "accession_parts_relator",
        "ifmissing" => "error"
      },

      "relator_type" => {
        "type" => "string",
        "dynamic_enum" => "accession_parts_relator_type",
        "ifmissing" => "error"
      },

      "ref" => {
        "type" => "JSONModel(:accession) uri",
        "ifmissing" => "error"
      },

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
