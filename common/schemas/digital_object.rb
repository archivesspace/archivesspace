# Schema inherits from the abstract_archival_object schema, and must only include extensions/overrides unique to digital object records.

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/digital_objects",
    "properties" => {

      "digital_object_id" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "level" => {"type" => "string", "dynamic_enum" => "digital_object_level"},
      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},
      "digital_object_type" => {
        "type" => "string",
        "dynamic_enum" => "digital_object_digital_object_type"
      },

      "file_versions" => {"type" => "array", "items" => {"type" => "JSONModel(:file_version) object"}},
      "restrictions" => {"type" => "boolean", "default" => false},
      "tree" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:digital_object_tree) uri",
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
      },
      "classifications" => {
              "type" => "array",
              "items" => {
                "type" => "object",
                "subtype" => "ref",
                "properties" => {
                  "ref" => {
                    "type" => [ { "type" => "JSONModel(:classification) uri"},
                                { "type" => "JSONModel(:classification_term) uri" }],
                    "ifmissing" => "error"
                  },
                  "_resolved" => {
                                "type" => "object",
                                "readonly" => "true"
                              }
                }
              }
      },

      "notes" => {
            "type" => "array",
            "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                                   {"type" => "JSONModel(:note_digital_object) object"}]},
          },
      "collection_management" => {"type" => "JSONModel(:collection_management) object"},
      "user_defined" => {"type" => "JSONModel(:user_defined) object"},

      "collection" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [
                {"type" => "JSONModel(:resource) uri"},
                {"type" => "JSONModel(:accession) uri"}
              ]
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "linked_instances" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => ["JSONModel(:resource) uri", "JSONModel(:archival_object) object"],
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        },
      },
      "metadata_rights_declarations" => {"type" => "array", "items" => {"type" => "JSONModel(:metadata_rights_declaration) object"}},
    },
  },
}
