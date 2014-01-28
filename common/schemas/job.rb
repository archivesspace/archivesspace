{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/jobs",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "filenames" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "string",
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

      "import_type" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "queue_position" => {
        "type" => "number",
        "readonly" => true
      }
    },
  },
}
