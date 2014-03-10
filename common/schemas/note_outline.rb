{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "publish" => {"type" => "boolean"},

      "levels" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:note_outline_level) object",
        }
      },

    },
  },
}
