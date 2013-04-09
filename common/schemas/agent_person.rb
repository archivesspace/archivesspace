{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_agent",
    "uri" => "/agents/people",
    "properties" => {
      "names" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:name_person) object"},
        "ifmissing" => "error",
        "minItems" => 1
      },

      "related_agents" => {
        "type" => "array",
        "items" => {
          "type" => [{"type" => "JSONModel(:agent_relationship_parentchild) object"},
                     {"type" => "JSONModel(:agent_relationship_earlierlater) object"},
                     {"type" => "JSONModel(:agent_relationship_associative) object"}],
        }
      },
    },
  },
}
