{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "items" => {
        "type" => "array",
        "items" => {
          "type" => [
            {"type" => "string"}, #SONModel(:note_outline_string) object",
            {"type" => "JSONModel(:note_outline_level) object"}
          ]
        }
      },

    },
  },
}
