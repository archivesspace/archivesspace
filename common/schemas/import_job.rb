{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "filenames" => {
        "type" => "array",
        "ifmissing" => "error",
        "minItems" => 1,
        "items" => {
          "type" => "string",
        }
      },

      "import_type" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "opts" => { "type" => "object" }

    }
  }
}
