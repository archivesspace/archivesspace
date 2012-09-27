{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/vocabularies",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "ref_id" => {"type" => "string", "minLength" => 1, "required" => true},
      "name" => {"type" => "string", "minLength" => 1, "required" => true},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) object"}, "readonly" => true},
    },

    "additionalProperties" => false,
  },
}
