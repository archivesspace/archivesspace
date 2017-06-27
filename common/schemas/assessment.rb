{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/assessments",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "records" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:accession) uri"},
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

      "accession_report" => {"type" => "string"},
      "appraisal" => {"type" => "string"},
      "container_list" => {"type" => "string"},
      "catalog_record" => {"type" => "string"},
      "control_file" => {"type" => "string"},

      "surveyed_by" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => "JSONModel(:agent_person) uri",
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
      "surveyed_date" => {"type" => "date", "ifmissing" => "error"},
      "surveyed_duration" => {"type" => "string"},
      "surveyed_extent" => {"type" => "string", "ifmissing" => "error"},

      "purpose" => {"type" => "string"},
      "scope" => {"type" => "string"},
      "is_material_sensitive" => {"type" => "boolean"},

      "materials" => {"type" => "array", "items" => {"type" => "JSONModel(:assessment_material) object"}},
      "conservation_issues" => {"type" => "array", "items" => {"type" => "JSONModel(:assessment_conservation_issue) object"}},
    },
  },
}
