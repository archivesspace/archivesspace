{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/agent_types",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "label" => {"type" => "string", "minLength" => 1, "required" => true}
    },

    "additionalProperties" => false,
  },
}
