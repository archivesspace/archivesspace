{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
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
      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_text) object"},
                               {"type" => "JSONModel(:note_citation) object"}]},
      },
    },
  },
}
