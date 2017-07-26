{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/assessments",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

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

      "accession_report" => {"type" => "boolean"},
      "appraisal" => {"type" => "boolean"},
      "container_list" => {"type" => "boolean"},
      "catalog_record" => {"type" => "boolean"},
      "control_file" => {"type" => "boolean"},
      "finding_aid_ead" => {"type" => "boolean"},
      "finding_aid_paper" => {"type" => "boolean"},
      "finding_aid_word" => {"type" => "boolean"},
      "finding_aid_spreadsheet" => {"type" => "boolean"},

      "surveyed_by" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:agent_person) uri"}],
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "surveyed_date" => {"type" => "date", "ifmissing" => "error"},
      "surveyed_duration" => {"type" => "string"},
      "surveyed_extent" => {"type" => "string", "ifmissing" => "error"},
      "review_required" => {"type" => "boolean"},

      "purpose" => {"type" => "string"},
      "scope" => {"type" => "string"},

      "sensitive_material" => {"type" => "boolean"},

      "formats" => {"type" => "array", "items" => {"type" => "JSONModel(:assessment_attribute) object"}},
      "conservation_issues" => {"type" => "array", "items" => {"type" => "JSONModel(:assessment_attribute) object"}},
      "ratings" => {"type" => "array", "items" => {"type" => "JSONModel(:assessment_attribute) object"}},

      "general_assessment_note" => {"type" => "string"},
      "special_format_note" => {"type" => "string"},
      "exhibition_value_note" => {"type" => "string"},
    },
  },
}
