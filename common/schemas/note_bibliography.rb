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

      "type" => {
        "type" => "string",
        "readonly" => true,
        "dynamic_enum" => "note_bibliography_type"
      },

      "items" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000}
      },
    },
  },
}
