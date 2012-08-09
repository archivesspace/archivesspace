{
  :schema => {
    "type" => "object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "id_0" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
      "id_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},

      "title" => {"type" => "string", "minLength" => 1, "required" => true},

      "parent" => {"type" => "string", "required" => false, "pattern" => "/repositories/[0-9]+/archival_objects/[0-9]+$"},
      "collection" => {"type" => "string", "required" => false, "pattern" => "/repositories/[0-9]+/collections/[0-9]+$"},

      "subjects" => {"type" => "array", "items" => { "type" => "string", "pattern" => "/subjects/[0-9]+$" } },
    },

    "additionalProperties" => false,
  },
}
