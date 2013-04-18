{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "ref_id" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A[a-zA-Z0-9\\-_:\\.]*\\z"},
      "component_id" => {"type" => "string", "maxLength" => 255, "required" => false, "default" => ""},

      "level" => {"type" => "string", "ifmissing" => "error", "dynamic_enum" => "archival_record_level"},
      "other_level" => {"type" => "string", "maxLength" => 255},

      "title" => {"type" => "string", "maxLength" => 16384, "ifmissing" => nil},
      "title_auto_generate" => {"type" => "boolean", "default" => false},
      
      "internal_only" => {"type" => "boolean", "default" => false},

      "parent" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:archival_object) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "resource" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:resource) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "position" => {"type" => "integer", "required" => false},

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },
    },



    "additionalProperties" => false,
  },
}
