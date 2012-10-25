{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/resources/:resource_id/tree",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "archival_object" => {"type" => "JSONModel(:archival_object) uri", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "required" => false},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:resource_tree) object" }
      }
    },
    "additionalProperties" => false,
  },
}
