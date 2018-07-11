{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/resources/:resource_id/tree",
    "parent" => "record_tree",
    "properties" => {
      "finding_aid_filing_title" => {"type" => "string", "maxLength" => 65000},
      "level" => {"type" => "string", "maxLength" => 255},
      "component_id" => {"type" => "string", "maxLength" => 255},
      "instance_types" => {"type" => "array", "items" => {"type" => "string"}},
      "containers" => {"type" => "array", "items" => {"type" => "object"}},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:resource_tree) object" }
      }
    },
  },
}
