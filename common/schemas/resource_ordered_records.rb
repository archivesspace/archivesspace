{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/resources/:id/ordered_records",
    "properties" => {
      "uris" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [ { "type" => "JSONModel(:resource) uri"},
                          { "type" => "JSONModel(:archival_object) uri" }],
              "ifmissing" => "error"
            },
            "display_string" => {"type" => "string", "readonly" => true},
            "depth" => {"type" => "integer", "readonly" => true},
            "level" => {"type" => "string", "readonly" => true},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },
    },
  },
}
