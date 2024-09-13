MERGEABLE_TYPES = [
                   {"type" => "JSONModel(:agent_person) uri"},
                   {"type" => "JSONModel(:agent_corporate_entity) uri"},
                   {"type" => "JSONModel(:agent_software) uri"},
                   {"type" => "JSONModel(:agent_family) uri"},
                  ]

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "uri" => "/merge_requests/:record_type",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "merge_destination" => {
        "type" => "object",
        "ifmissing" => "error",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => MERGEABLE_TYPES,
            "ifmissing" => "error"
          },
        }
      },

      "merge_candidates" => {
        "type" => "array",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => MERGEABLE_TYPES,
              "ifmissing" => "error"
            },
          }
        }
      },

      "selections" => {"type" => "object"},
    },
  },
}
