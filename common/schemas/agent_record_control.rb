{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "maintenance_status" => {
        "type" => "string",
        "dynamic_enum" => "maintenance_status",
        "ifmissing" => "error"
      },
      "publication_status" => {
        "type" => "string",
        "dynamic_enum" => "publication_status",
        "required" => false
      },
      "romanization" => {
        "type" => "string",
        "dynamic_enum" => "romanization",
        "required" => false
      },
      "government_agency_type" => {
        "type" => "string",
        "dynamic_enum" => "government_agency_type",
        "required" => false
      },
      "reference_evaluation" => {
        "type" => "string",
        "dynamic_enum" => "reference_evaluation",
        "required" => false
      },
      "name_type" => {
        "type" => "string",
        "dynamic_enum" => "name_type",
        "required" => false
      },
      "level_of_detail" => {
        "type" => "string",
        "dynamic_enum" => "level_of_detail",
        "required" => false
      },
      "modified_record" => {
        "type" => "string",
        "dynamic_enum" => "modified_record",
        "required" => false
      },
      "cataloging_source" => {
        "type" => "string",
        "dynamic_enum" => "cataloging_source",
        "required" => false
      },
      "language" => {
        "type" => "string",
        "dynamic_enum" => "language_iso639_2",
        "required" => false
      },
      "script" => {
        "type" => "string",
        "dynamic_enum" => "script_iso15924",
        "required" => false
      },
      "language_note" => {"type" => "string", "maxLength" => 65000},
      "maintenance_agency" => {"type" => "string", "maxLength" => 65000},
      "agency_name" => {"type" => "string", "maxLength" => 65000},
      "maintenance_agency_note" => {"type" => "string", "maxLength" => 65000},
      "require_record" => {
        "type" => "boolean",
        "default" => true,
      }
    }
  }
}
