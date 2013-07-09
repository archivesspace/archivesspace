{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_objects/:digital_object_id/tree",
    "parent" => "record_tree",
    "properties" => {
      "level" => {"type" => "string", "maxLength" => 255},
      "digital_object_type" => {"type" => "string", "maxLength" => 255},
      "file_versions" => {"type" => "array", "items" => {"type" => "object"}},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:digital_object_tree) object" }
      }
    },
  },
}
