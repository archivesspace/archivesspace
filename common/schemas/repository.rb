{
  :schema => {
    "type" => "object",
    "properties" => {
      "repo_id" => {"type" => "string", "required" => true, "minLength" => 1},
      "description" => {"type" => "string", "required" => true, "default" => ""},
    },

    "additionalProperties" => false,
  },
}
