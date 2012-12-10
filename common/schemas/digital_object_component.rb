{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/digital_object_components",
    "properties" => {

      "component_id" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "label" => {"type" => "string"},

      "parent" => {"type" => "JSONModel(:digital_object_component) uri", "required" => false},
      "digital_object" => {"type" => "JSONModel(:digital_object) uri", "required" => false},
      "position" => {"type" => "integer", "required" => false},
      
      "notes" => {
            "type" => "array",
            "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                                   {"type" => "JSONModel(:note_digital_object) object"}]},
          },

    },

    "additionalProperties" => false
  },
}
