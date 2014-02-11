{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/preferences",

    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "user_id" => {"type" => "integer"},

      "defaults" => {"type" => "JSONModel(:defaults) object"},
    },
  },
}
