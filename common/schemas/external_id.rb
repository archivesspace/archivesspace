{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "external_id" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "source" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
    }
  },
}
