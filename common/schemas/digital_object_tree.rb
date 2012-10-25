{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_objects/:digital_object_id/tree",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "digital_object_component" => {"type" => "JSONModel(:digital_object_component) uri", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "required" => false},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:digital_object_tree) object" }
      }
    },
    "additionalProperties" => false,
  },
}
