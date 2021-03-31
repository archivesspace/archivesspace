{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "resource_id" => {
        "type" => "string",
        "ifmissing" => "error",
      },
      "filename" => {
        "type" => "string",
        "ifmissing" => "error",
      },
      "load_type" => {
        "type" => "string",
      },
      "content_type" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "only_validate" => {
        "type" => "string",
      },
    },
  },
}
