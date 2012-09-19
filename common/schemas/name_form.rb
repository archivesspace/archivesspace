{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/agents/:agent_id/name_forms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "kind" => {"type" => "string", "required" => true},

      "sort_name" => {"type" => "string", "required" => true}
    },

    "additionalProperties" => false,
  },
}
