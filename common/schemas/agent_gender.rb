{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "gender" => {"type" => "string", "dynamic_enum" => "gender"},

      "dates" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:structured_date_label) object"}
      },
      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_text) object"},
                               {"type" => "JSONModel(:note_citation) object"}]},
      },
      "require_record" => {
        "type" => "boolean",
        "default" => true,
      }
    },
  },
}
