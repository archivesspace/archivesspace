{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "language_and_script" => {"type" => "JSONModel(:language_and_script) object"},
      "notes" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:note_langmaterial) object"},
      },
    },
  },
}
