{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "repo_code" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
      "description" => {"type" => "string", "ifmissing" => "error", "default" => ""},
    },

    "additionalProperties" => false,
  },
}
