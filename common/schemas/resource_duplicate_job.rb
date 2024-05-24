{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "source" => {
        "type" => "string",
        "ifmissing" => "error"
      }
    }
  }
}
