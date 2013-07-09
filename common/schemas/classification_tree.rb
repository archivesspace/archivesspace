{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/classifications/:classification_id/tree",
    "parent" => "record_tree",
    "properties" => {
      "identifier" => {"type" => "string", "maxLength" => 255},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:classification_tree) object" }
      }
    },
  },
}
