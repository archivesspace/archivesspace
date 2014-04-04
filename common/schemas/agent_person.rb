{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
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

      "display_name" => {
        "type" => "JSONModel(:name_person) object",
        "readonly" => true
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
