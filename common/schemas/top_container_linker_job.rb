{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "filename" => {
        "type" => "string",
        "ifmissing" => "error",
      }

    }
  }
}
