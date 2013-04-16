{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/subjects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {"type" => "string", "readonly" => true},

      "external_ids" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "external_id" => {"type" => "string", "maxLength" => 255},
            "source" => {"type" => "string", "maxLength" => 255},
          }
        }
      },

      "source" => {"type" => "string", "dynamic_enum" => "subject_source"},
      
      "scope_note" => {"type" => "string"},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}, "ifmissing" => "error", "minItems" => 1},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"},
      "ref_id" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A[\\S]*\\z"},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
    },

    "additionalProperties" => false,
  },
}
