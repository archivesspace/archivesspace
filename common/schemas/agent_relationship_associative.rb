{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "subtype" => "ref",
    "parent" => "abstract_agent_relationship",
    "properties" => {
      "relator" => {
        "type" => "string",
        "enum" => ["is_associative_with"],
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
