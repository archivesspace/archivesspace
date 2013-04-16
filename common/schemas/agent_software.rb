{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_agent",
    "uri" => "/agents/software",
    "properties" => {
      "names" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:name_software) object"},
        "ifmissing" => "error",
        "minItems" => 1
      },
    },
  },
}
