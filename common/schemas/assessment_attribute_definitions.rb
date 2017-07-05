{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/assessment_attribute_definitions",
    "properties" => {
      "definitions" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "id" => { "type" => "integer" },
            "label" => { "type" => "string", "ifmissing" => "error" },
            "type" => { "enum" => ["rating", "format", "conservation_issue"], "ifmissing" => "error" },
          }
        }
      }
    }
  }
}
