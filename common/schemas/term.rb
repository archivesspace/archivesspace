{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/terms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "term" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},
      "term_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["Cultural context", "Function", "Geographic", "Genre / form", "Occupation", "Style / period", "Technique", "Temporal", "Topical", "Uniform title"]},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"}
    },

    "additionalProperties" => false,
  },
}
