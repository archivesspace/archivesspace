{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 32672},
        "minItems" => 0,
        "ifmissing" => nil,
      },

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "value" => {"type" => "string", "ifmissing" => "error", "maxLength" => 32672},
            "type" => {"type" => "string", "ifmissing" => "error", "maxLength" => 32672},
            "reference" => {"type" => "string", "maxLength" => 32672},
            "reference_text" => {"type" => "string", "maxLength" => 32672},
          }}
      },
    },

    "additionalProperties" => false,
  },
}
