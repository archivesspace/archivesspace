{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "maxLength" => 16384, "ifmissing" => "error", "minLength" => 1},
      "location" => {"type" => "string", "maxLength" => 16384, "ifmissing" => "error", "default" => ""},
      "publish" => {"type" => "boolean"},
    },
  },
}
