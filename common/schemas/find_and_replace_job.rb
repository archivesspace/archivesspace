{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/find_and_replace_jobs",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "arguments" => {
        "type" => "object",
        "ifmissing" => "error",
        "properties" => {
          "find" => {
            "type" => "string",
            "ifmissing" => "error"
          },
          "replace" => {
            "type" => "string",
            "ifmissing" => "error"
          }
        }
      },

      "scope" => {
        "type" => "object",
        "ifmissing" => "error",
        "properties" => {
          "jsonmodel_type" => {
            "type" => "string",
            "ifmissing" => "error"
          },
          "property" => {
            "type" => "string",
            "ifmissing" => "error"
          },
          "base_record_uri" => {
            "type" => "string",
            "ifmissing" => "error"
          }
        }
      },

      "time_submitted" => {
        "type" => "date-time",
        "readonly" => true
      },

      "time_started" => {
        "type" => "date-time",
        "readonly" => true
      },

      "time_finished" => {
        "type" => "date-time",
        "readonly" => true
      },

      "owner" => {
        "type" => "string",
        "readonly" => true
      },

      "status" => {
        "type" => "string",
        "enum" => ["running", "completed", "canceled", "queued", "failed"],
        "default" => "queued",
        "readonly" => true
      },

      "queue_position" => {
        "type" => "number",
        "readonly" => true
      }
    }
  }
}
