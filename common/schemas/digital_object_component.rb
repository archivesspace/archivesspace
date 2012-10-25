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
      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },

      "parent" => {"type" => "JSONModel(:digital_object_component) uri", "required" => false},
      "digital_object" => {"type" => "JSONModel(:digital_object) uri", "required" => false},

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

    },

    "additionalProperties" => false
  },
}
