{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/agents",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "type" => {"type" => "JSONModel(:agent_type) uri", "required" => true},
    },

    "additionalProperties" => false,
  },
}
