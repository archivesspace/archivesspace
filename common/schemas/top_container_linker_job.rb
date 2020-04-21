{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "resource_id" => { 
        "type" => "number",
        "ifmissing" => "error"
      },
      "filename" => {
        "type" => "string",
        "ifmissing" => "error",
      },
      "content_type" => {
        "type" => "string",
        "ifmissing" => "error"
      }

    }
  }
}
