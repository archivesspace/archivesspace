{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "external_id" => {"type" => "string", "maxLength" => 255},
      "source" => {"type" => "string", "maxLength" => 255},
    }
  },
}
