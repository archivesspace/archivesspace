{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "note_multipart_type"
      },
      
      "rights_restriction" => {
        "type" => "JSONModel(:rights_restriction) object"
      },

      "subnotes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_chronology) object"},
                               {"type" => "JSONModel(:note_orderedlist) object"},
                               {"type" => "JSONModel(:note_definedlist) object"},
                               {"type" => "JSONModel(:note_text) object"}]},
      },
    },
  },
}
