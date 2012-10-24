{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_object_components",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "component_id" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "label" => {"type" => "string"},
      "title" => {"type" => "string"},
      "language" => {"type" => "string"},
    },

    "additionalProperties" => false
  },
}
