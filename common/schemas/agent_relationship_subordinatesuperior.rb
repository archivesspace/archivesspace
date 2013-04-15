{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_agent_relationship",
    "subtype" => "ref",
    "properties" => {
      "relator" => {
        "type" => "string",
        "enum" => ["is_subordinate_to", "is_superior_of"],
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
