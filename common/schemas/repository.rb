{
  :schema => {
    "type" => "object",
    "uri" => "/repositories",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "repo_code" => {"type" => "string", "required" => true, "minLength" => 1},
      "description" => {"type" => "string", "required" => true, "default" => ""},
    },

    "additionalProperties" => false,
  },
}
