{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_agent",
    "uri" => "/agents/software",
    "properties" => {
      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},
      "display_name" => {
        "type" => "JSONModel(:name_software) object",
        "readonly" => true
      },

      "names" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:name_software) object"},
        "ifmissing" => "error",
        "minItems" => 1
      },
    },
  },
}
