{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/preferences",

    "properties" => {
      "user_id" => {"type" => "integer"},

      "defaults" => {
        "type" => "string",
        "maxLength" => 65000,
        "ifmissing" => "error",
      },

    },
  },
}
