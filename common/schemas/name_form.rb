{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/agents/:agent_id/name_forms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "kind" => {"type" => "string", "ifmissing" => "error"},

      "sort_name" => {"type" => "string", "ifmissing" => "error"}
    },
  },
}
