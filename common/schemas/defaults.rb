accession_browse_column_enum = [
                      "identifier", "accession_date", "acquisition_type", "resource_type",
                      "restrictions_apply", "access_restrictions", "use_restrictions",
                      "publish", 'no_value'
                     ]
resource_browse_column_enum = [
                      "identifier", "resource_type", "level", "restrictions",
                      "ead_id", "finding_aid_status", "publish", 'no_value'
                     ]
digital_object_browse_column_enum = [
                      "digital_object_id", "digital_object_type", "level", "restrictions",
                      "publish", 'no_value'
                     ]
locale_enum = I18n.supported_locales.keys
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "show_suppressed" =>  {"type" => "boolean", "required" => false},
      "publish" =>  {"type" => "boolean", "required" => false},

      "locale" => {
        "type" => "string",
        "enum" => locale_enum,
        "required" => false
      },

      "accession_browse_column_1" => {
        "type" => "string",
        "enum" => accession_browse_column_enum,
        "required" => false
      },
      "accession_browse_column_2" => {
        "type" => "string",
        "enum" => accession_browse_column_enum,
        "required" => false
      },
      "accession_browse_column_3" => {
        "type" => "string",
        "enum" => accession_browse_column_enum,
        "required" => false
      },
      "accession_browse_column_4" => {
        "type" => "string",
        "enum" => accession_browse_column_enum,
        "required" => false
      },
      "accession_browse_column_5" => {
        "type" => "string",
        "enum" => accession_browse_column_enum,
        "required" => false
      },

      "resource_browse_column_1" => {
        "type" => "string",
        "enum" => resource_browse_column_enum,
        "required" => false
      },
      "resource_browse_column_2" => {
        "type" => "string",
        "enum" => resource_browse_column_enum,
        "required" => false
      },
      "resource_browse_column_3" => {
        "type" => "string",
        "enum" => resource_browse_column_enum,
        "required" => false
      },
      "resource_browse_column_4" => {
        "type" => "string",
        "enum" => resource_browse_column_enum,
        "required" => false
      },
      "resource_browse_column_5" => {
        "type" => "string",
        "enum" => resource_browse_column_enum,
        "required" => false
      },

      "digital_object_browse_column_1" => {
        "type" => "string",
        "enum" => digital_object_browse_column_enum,
        "required" => false
      },
      "digital_object_browse_column_2" => {
        "type" => "string",
        "enum" => digital_object_browse_column_enum,
        "required" => false
      },
      "digital_object_browse_column_3" => {
        "type" => "string",
        "enum" => digital_object_browse_column_enum,
        "required" => false
      },
      "digital_object_browse_column_4" => {
        "type" => "string",
        "enum" => digital_object_browse_column_enum,
        "required" => false
      },
      "digital_object_browse_column_5" => {
        "type" => "string",
        "enum" => digital_object_browse_column_enum,
        "required" => false
      },

      "default_values" => {
        "type" => "boolean",
        "required" => false,
        "default" => false
      },

      "note_order" => {
        "type" => "array",
        "items" => {"type" => "string"}
      }

    },
  },
}
