{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
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
            "external_id" => {"type" => "string"},
            "source" => {"type" => "string"},
          }
        }
      },

      "source" => {"type" => "string", "dynamic_enum" => "subject_source"},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}, "ifmissing" => "error", "minItems" => 1},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"},
      "ref_id" => {"type" => "string", "pattern" => "^[\\S]*$"},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
    },

    "additionalProperties" => false,
  },
}
