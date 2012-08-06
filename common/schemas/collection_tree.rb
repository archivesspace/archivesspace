{
  :schema => {
    "type" => "object",
    "uri" => "/repositories/:repo_id/collections/:collection_id/tree",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "archival_object" => {"type" => "string", "required" => false, "pattern" => "/repositories/[0-9]+/archival_objects/[0-9]+$"},
      "title" => {"type" => "string", "minLength" => 1, "required" => true},
      "children" => {"type" => "array", "additionalItems" => false, "items" => { "$ref" => "#" }}
    },
    "additionalProperties" => false,
  },
}
