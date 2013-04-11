{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_agent_relationship",
    "subtype" => "ref",
    "properties" => {
      "relator" => {
        "type" => "string",
        "enum" => ["is_earlier_form_of", "is_later_form_of"],
        "ifmissing" => "error"
      },

      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_person) uri"},
                   {"type" => "JSONModel(:agent_corporate_entity) uri"},
                   {"type" => "JSONModel(:agent_family) uri"}],
        "ifmissing" => "error"
      },

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
