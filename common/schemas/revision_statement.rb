{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/revision_statement",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "date" => {"type" => "string", "maxLength" => 255},
      "description" => {"type" => "string", "maxLength" => 65000},
    },
  },
}
