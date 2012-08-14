{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/vocabularies",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "ref_id" => {"type" => "string", "minLength" => 1, "required" => true},
      "name" => {"type" => "string", "minLength" => 1, "required" => true}
    },

    "additionalProperties" => false,
  },
}
