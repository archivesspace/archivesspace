{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_agent_relationship",
    "subtype" => "ref",
    "properties" => {
      "relator" => {
        "type" => "string",
        "dynamic_enum" => "agent_relationship_subordinatesuperior_relator",
        "ifmissing" => "error"
      },

      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
        "ifmissing" => "error"
      },

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
