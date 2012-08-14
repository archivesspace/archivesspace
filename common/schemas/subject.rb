{
  :schema => {
    "type" => "object",
    "uri" => "/subjects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "term" => {"type" => "string", "minLength" => 1, "required" => true},
      "term_type" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["Cultural context", "Function", "Geographic", "Genre / form", "Occupation", "Style / period", "Technique", "Temporal", "Topical", "Uniform title"]},
      "parent" => {"type" => "string", "required" => false, "pattern" => "/subjects/[0-9]+$"},
      "vocabulary" => {"type" => "string", "required" => true, "pattern" => "/vocabularies/[0-9]+$"}
    },

    "additionalProperties" => false,
  },
}
