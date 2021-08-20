{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "current" => {"type" => "string", "required" => false},
      "previous" => {
        "type" => "array",
        "items" => {
          "type" => "string"
        }
      }
    }
  }
}
