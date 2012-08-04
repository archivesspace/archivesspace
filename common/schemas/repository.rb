{
  :schema => {
    "type" => "object",
    "uri" => "/repositories",
    "properties" => {
      "repo_code" => {"type" => "string", "required" => true, "minLength" => 1},
      "description" => {"type" => "string", "required" => true, "default" => ""},
    },

    "additionalProperties" => false,
  },
}
