JOB_TYPES = [
             {"type" => "JSONModel(:import_job) object"},
             {"type" => "JSONModel(:find_and_replace_job) object"},
             {"type" => "JSONModel(:print_to_pdf_job) object"},
             {"type" => "JSONModel(:report_job) object"}
            ]

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/jobs",
    "properties" => {

      "uri" => {"type" => "string", "required" => false},

      "job_type" => {
        "type" => "string",
        "ifmissing" => "error",
        "minLength" => 1,
        "dynamic_enum" => "job_type"
      },

      "job" => {
        "type" => JOB_TYPES
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
