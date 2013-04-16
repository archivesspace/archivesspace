{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000},
        "minItems" => 0,
        "ifmissing" => nil,
      },

      "items" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "value" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000},
            "type" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000},
            "reference" => {"type" => "string", "maxLength" => 65000},
            "reference_text" => {"type" => "string", "maxLength" => 65000},
          }}
      },
    },

    "additionalProperties" => false,
  },
}
