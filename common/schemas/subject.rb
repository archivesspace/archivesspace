{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/subjects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}, "ifmissing" => "error", "minItems" => 1},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},
    },

    "additionalProperties" => false,
  },
}
