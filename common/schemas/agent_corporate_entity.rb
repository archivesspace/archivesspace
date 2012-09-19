{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_agent",
    "uri" => "/agents/corporate_entities",
    "properties" => {
      "names" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:name_corporate_entity) uri_or_object"},
        "ifmissing" => "error",
        "minItems" => 1
      },
    },
  },
}