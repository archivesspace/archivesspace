{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "id" => {"type" => "string", "ifmissing" => "error"},
      "record_uri" => {"type" => "string", "ifmissing" => "error"},
      "title" => {"type" => "string", "minLength" => 1, "required" => false},
      "node_type" => {"type" => "string"},
      "children" => {
        "type" => "array",
        "additionalItems" => false,
        "items" => { "type" => "JSONModel(:record_tree) object" }
      }
    },
    "additionalProperties" => false,
  },
}
