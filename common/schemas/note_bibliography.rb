{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "items" => {
        "type" => "array",
        "items" => {"type" => "string"}
      },
    },

    "additionalProperties" => false,
  },
}
