{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "portion" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["whole", "part"]},
      "number" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},
      "extent_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["cassettes", "cubic_feet", "leafs", "linear_feet", "photographic_prints", "photographic_slides", "reels", "sheets", "volumes"]},

      "container_summary" => {"type" => "string", "required" => false},
      "physical_details" => {"type" => "string", "required" => false},
      "dimensions" => {"type" => "string", "required" => false},
    },

    "additionalProperties" => false,
  },
}
