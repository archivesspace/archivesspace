{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/with_agent",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "repository" => {"type" => "JSONModel(:repository) object", "ifmissing" => "error"},
      "agent_representation" => {"type" => "JSONModel(:agent_corporate_entity) object"},
    },
  },
}
