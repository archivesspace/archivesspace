{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/agents",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "agent_type" => {"type" => "JSONModel(:agent_type) uri", "required" => true},

      "name_forms" => {"type" => "array", "items" => {"type" => "JSONModel(:name_form) uri_or_object"},
        "ifmissing" => "error", "minItems" => 1},
    },

    "additionalProperties" => false,
  },
}
