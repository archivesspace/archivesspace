{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "content" => {"type" => "string", "ifmissing" => nil},

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "value" => {"type" => "string", "ifmissing" => "error"},
            "type" => {"type" => "string", "ifmissing" => "error"},
            "reference" => {"type" => "string", "ifmissing" => "error"},
            "reference_text" => {"type" => "string", "ifmissing" => "error"},
          }}
      },
    },

    "additionalProperties" => false,
  },
}
