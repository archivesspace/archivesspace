{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/terms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "term" => {"type" => "string", "minLength" => 1, "required" => true},
      "term_type" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["Cultural context", "Function", "Geographic", "Genre / form", "Occupation", "Style / period", "Technique", "Temporal", "Topical", "Uniform title"]},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "required" => true}
     },

    "additionalProperties" => false,
  },
}
