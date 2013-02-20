{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "content" => {
        "type" => "array",
        "items" => {"type" => "string"},
        "minItems" => 0,
        "ifmissing" => nil,
      },

      "items" => {
        "type" => "array",
        "items" => {"type" => "string"}
      },
    },

    "additionalProperties" => false,
  },
}
