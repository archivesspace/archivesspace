{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/rde_templates",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "name" => {"type" => "string", "ifmissing" => "error"},
      "record_type" => {"type" => "string", "ifmissing" => "error", "enum" => ['archival_object', 'digital_object_component']},
      "order" => {"type" => "array", "items" => {"type" => "string"}},
      "visible" => {"type" => "array", "items" => {"type" => "string"}},
      "defaults" => {"type" => "object"},
    },
  },
}
