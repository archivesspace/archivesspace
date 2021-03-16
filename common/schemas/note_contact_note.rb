{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "date_of_contact" => {
        "type" => "string",
        "maxLength" => 65000,
        "ifmissing" => "error",
      },

      "contact_notes" => {
        "type" => "string",
        "maxLength" => 65000,
        "ifmissing" => "error",
      },

      "publish" => {"type" => "boolean"},
    }
  },
}
