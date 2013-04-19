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
      "level" => {"type" => "string", "maxLength" => 255},
      "node_type" => {"type" => "string", "maxLength" => 255},
      "publish" => {"type" => "boolean", "default" => true},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:record_tree) object" }
      }
    },
    "additionalProperties" => false,
  },
}
