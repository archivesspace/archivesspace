browse_column_enum = [
                      "identifier", "accession_date", "acquisition_type", "resource_type",
                      "restrictions_apply", "access_restrictions", "use_restrictions",
                      "publish"
                     ]
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "show_suppressed" =>  {"type" => "boolean", "required" => false},
      "publish" =>  {"type" => "boolean", "required" => false},
      "accession_browse_label_title" => {"type" => "string", "required" => false},
      "accession_browse_label_identifier" => {"type" => "string", "required" => false},

      "accession_browse_column_1" => {
        "type" => "string",
        "enum" => browse_column_enum,
        "required" => false
      },
      "accession_browse_column_2" => {
        "type" => "string",
        "enum" => browse_column_enum,
        "required" => false
      },
      "accession_browse_column_3" => {
        "type" => "string",
        "enum" => browse_column_enum,
        "required" => false
      },
      "accession_browse_column_4" => {
        "type" => "string",
        "enum" => browse_column_enum,
        "required" => false
      },
      "accession_browse_column_5" => {
        "type" => "string",
        "enum" => browse_column_enum,
        "required" => false
      },
    },
  },
}
