{
  :schema => {
    "type" => "object",
    "uri" => "/repositories/:repo_id/collections",
    "properties" => {
      "title" => {"type" => "string", "minLength" => 1, "required" => true},
    },

    "additionalProperties" => false,
  },
}
