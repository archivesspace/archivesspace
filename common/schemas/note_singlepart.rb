{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "note_singlepart_type"

      },
    },

    "additionalProperties" => false,
  },
}
