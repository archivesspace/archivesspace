{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "definition_id" => { "type" => "integer", "ifmissing" => "error" },
      "label" => { "type" => "string", "readonly" => true },
      "global" => { "type" => "boolean", "readonly" => true },
      "value" => { "type" => "string" },
      "note" => { "type" => "string" },
      "readonly" => { "type" => "boolean", "default" => false },
    }
  }
}
