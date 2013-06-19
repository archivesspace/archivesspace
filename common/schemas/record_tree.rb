{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "id" => {"type" => "integer", "ifmissing" => "error"},
      "record_uri" => {"type" => "string", "ifmissing" => "error"},
      "title" => {"type" => "string", "minLength" => 1, "required" => false, "maxLength" => 16384},
      "publish" => {"type" => "boolean", "default" => true},
      "node_type" => {"type" => "string", "maxLength" => 255},
    },
    "additionalProperties" => false,
  },
}
