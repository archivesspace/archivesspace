{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {


      "find" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "replace" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "record_type" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "property" => {
        "type" => "string",
        "ifmissing" => "error"
      },

      "base_record_uri" => {
        "type" => "string",
        "ifmissing" => "error"
      }
    }
  }
}
