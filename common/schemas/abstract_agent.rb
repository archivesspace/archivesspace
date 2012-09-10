{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "type" => {
        "type" => "string",
        "required" => false,
        "enum" => ["Person", "Corporation", "Software", "Family"]
      },
    },
  },
}
