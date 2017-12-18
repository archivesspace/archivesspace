{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000},
        "minItems" => 1,
        "ifmissing" => "error",
      },

      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "note_rights_statement_type"
      },
    },
  },
}
