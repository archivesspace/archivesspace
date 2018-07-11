{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/digital_object_components",
    "properties" => {

      "component_id" => {"type" => "string", "maxLength" => 255},
      "label" => {"type" => "string", "maxLength" => 255},
      "title" => {"type" => "string", "maxLength" => 16384, "ifmissing" => nil},
      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

      "file_versions" => {"type" => "array", "items" => {"type" => "JSONModel(:file_version) object"}},

      "parent" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:digital_object_component) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "digital_object" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:digital_object) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        },
        "ifmissing" => "error"
      },

      "position" => {"type" => "integer", "required" => false},

      "notes" => {
            "type" => "array",
            "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                                   {"type" => "JSONModel(:note_digital_object) object"}]},
          },

      "has_unpublished_ancestor" => {"type" => "boolean", "readonly" => "true"},

    },
  },
}
