{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "parent" => "abstract_agent_relationship",
    "properties" => {
      "relator" => {
        "type" => "string",
        "dynamic_enum" => "agent_relationship_associative_relator",
        "ifmissing" => "error"
      },

      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_person) uri"},
                   {"type" => "JSONModel(:agent_family) uri"},
                   {"type" => "JSONModel(:agent_corporate_entity) uri"}],
        "ifmissing" => "error"
      },

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
