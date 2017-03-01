{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/jobs",
    "properties" => {

      "uri" => {"type" => "string", "required" => false},

      "job" => {
        "type" => "object"
      },
   
      "job_params" => { 
        "type" => "string",
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
    },
  },
}
