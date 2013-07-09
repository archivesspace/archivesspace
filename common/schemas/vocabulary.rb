{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/vocabularies",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "ref_id" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},
      "name" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri"}, "readonly" => true},
    },
  },
}
