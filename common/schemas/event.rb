{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/events",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "external_ids" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "external_id" => {"type" => "string", "maxLength" => 255},
            "source" => {"type" => "string", "maxLength" => 255},
          }
        }
      },

      "event_type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "event_event_type"
      },

      "date" => {"type" => "JSONModel(:date) object", "ifmissing" => "error"},
      "outcome" => {"type" => "string", "dynamic_enum" => "event_outcome"},
      "outcome_note" => {"type" => "string", "maxLength" => 255},

      "suppressed" => {"type" => "boolean"},

      "linked_agents" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "dynamic_enum" => "linked_agent_event_roles",
              "ifmissing" => "error",
            },
            "ref" => {"type" => [
                                 {"type" => "JSONModel(:agent_corporate_entity) uri"},
                                 {"type" => "JSONModel(:agent_family) uri"},
                                 {"type" => "JSONModel(:agent_person) uri"},
                                 {"type" => "JSONModel(:agent_software) uri"}],
              "ifmissing" => "error"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "linked_records" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "role" => {
              "type" => "string",
              "dynamic_enum" => "linked_event_archival_record_roles",
              "ifmissing" => "error",
            },
            "ref" => {
              "type" => [{"type" => "JSONModel(:agent_person) uri"},
                         {"type" => "JSONModel(:agent_family) uri"},
                         {"type" => "JSONModel(:agent_corporate_entity) uri"},
                         {"type" => "JSONModel(:agent_software) uri"},                                                  
                         {"type" => "JSONModel(:accession) uri"},
                         {"type" => "JSONModel(:resource) uri"},
                         {"type" => "JSONModel(:digital_object) uri"},
                         {"type" => "JSONModel(:archival_object) uri"}],
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },
    },

    "additionalProperties" => false
  }
}
