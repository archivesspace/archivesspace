{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_agent",
    "uri" => "/agents/people",
    "properties" => {
      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},
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

      "agent_genders" => {
        "required" => false,
        "type" => "array",
        "items" => {"type" => "JSONModel(:agent_gender) object"}
      },

      "related_agents" => {
        "type" => "array",
        "items" => {
          "type" => [{"type" => "JSONModel(:agent_relationship_parentchild) object"},
                     {"type" => "JSONModel(:agent_relationship_earlierlater) object"},
                     {"type" => "JSONModel(:agent_relationship_identity) object"},
                     {"type" => "JSONModel(:agent_relationship_hierarchical) object"},
                     {"type" => "JSONModel(:agent_relationship_temporal) object"},
                     {"type" => "JSONModel(:agent_relationship_family) object"},
                     {"type" => "JSONModel(:agent_relationship_associative) object"}],
        }
      },
    },
  },
}
