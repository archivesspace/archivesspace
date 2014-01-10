{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "value" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000},
      "type" => {"type" => "string", "ifmissing" => "error", "dynamic_enum" => "note_index_item_type"},
      "reference" => {"type" => "string", "maxLength" => 65000},
      "reference_text" => {"type" => "string", "maxLength" => 65000},
      "reference_ref" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "string", "readonly" => true},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      }
    },
  }
}
