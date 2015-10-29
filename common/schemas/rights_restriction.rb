{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "begin" => {
        "type" => "string",
      },

      "end" => {
        "type" => "string",
      },

      "local_access_restriction_type" => {
        "type" => "array",
        "items" => {"type" => "string",
                    "dynamic_enum" => "restriction_type"},
      },

      "linked_records" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:archival_object) uri"},
                               {"type" => "JSONModel(:resource) uri"}]},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "restriction_note_type" => {
        "type" => "string",
        "readonly" => "true"
      },
    }
  }
}
