{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "title" => {"type" => "string", "maxLength" => 16384},

      "publish" => {"type" => "boolean"},

      "enumeration" => {
        "type" => "string",
        "dynamic_enum" => "note_orderedlist_enumeration"
      },

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "string",
          "maxLength" => 65000
        }
      }
    },
  },
}
