{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/agents/:agent_id/name_forms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false, "readonly" => true},

      "kind" => {"type" => "string", "ifmissing" => "error"},

      "sort_name" => {"type" => "string", "ifmissing" => "error"}
    },

    "additionalProperties" => false,
  },
}
