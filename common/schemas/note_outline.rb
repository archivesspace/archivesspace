{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "publish" => {"type" => "boolean", "default" => true},

      "levels" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:note_outline_level) object",
        }
      },

    },

    "additionalProperties" => false,
  },
}
