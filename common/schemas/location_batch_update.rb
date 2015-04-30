{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "location",
    "properties" => {
      "building" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => nil},
      "record_uris" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:location) uri"
        }
      }

    },
  },
}
