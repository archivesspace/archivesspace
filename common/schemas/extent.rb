{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/extents",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "portion" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["whole", "part"]},
      "number" => {"type" => "integer", "minLength" => 1, "required" => true},
      "extent_type" => {"type" => "string", "minLength" => 1, "required" => true, "enum" => ["cassettes", "cubic_feet", "leafs", "linear_feat", "photographic_prints", "photographic_slides", "reels", "sheets", "volumes"]},

      "container_summary" => {"type" => "string", "required" => false},
      "physical_details" => {"type" => "string", "required" => false},
      "dimensions" => {"type" => "string", "required" => false},
    },

    "additionalProperties" => false,
  },
}
