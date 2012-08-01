{
  :schema => {
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "minLength" => 1, "required" => true},
      "repository" => {"type" => "string", "required" => true, "pattern" => "/repositories/[0-9]+$"},
    },

    "additionalProperties" => false,
  },
}
