{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "identifier" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "description" => {"type" => "string", "maxLength" => 65000},

      "publish" => {"type" => "boolean", "default" => true, "readonly" => true},

      "path_from_root" => {
        "type" => "array",
        "readonly" => true,
        "items" => {
          "type" => "object",
          "properties" => {
            "identifier" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
            "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
          }
        }
      },
      
      "linked_records" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [
                         {"type" => "JSONModel(:accession) uri"},
                         {"type" => "JSONModel(:resource) uri"},
                        ],
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "creator" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"},
                               {"type" => "JSONModel(:agent_family) uri"},
                               {"type" => "JSONModel(:agent_person) uri"},
                               {"type" => "JSONModel(:agent_software) uri"}],
            "ifmissing" => "error"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
    },
  },
}
