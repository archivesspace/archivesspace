{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "arguments" => {
        "type" => "object",
        "ifmissing" => "error",
        "properties" => {
          "find" => {
            "type" => "string",
            "ifmissing" => "error"
          },
          "replace" => {
            "type" => "string",
            "ifmissing" => "error"
          }
        }
      },

      "scope" => {
        "type" => "object",
        "ifmissing" => "error",
        "properties" => {
          "jsonmodel_type" => {
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
      },

    }
  }
}
