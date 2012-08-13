{
  :schema => {
    "type" => "object",
    "uri" => "/vocabularies",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "name" => {"type" => "string", "minLength" => 1, "required" => true}
    },

    "additionalProperties" => false,
  },
}
