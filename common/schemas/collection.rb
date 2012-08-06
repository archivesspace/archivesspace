{
  :schema => {
    "type" => "object",
    "uri" => "/repositories/:repo_id/collections",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {"type" => "string", "minLength" => 1, "required" => true},
    },

    "additionalProperties" => false,
  },
}
