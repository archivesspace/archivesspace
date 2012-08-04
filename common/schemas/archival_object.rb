{
  :schema => {
    "type" => "object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "id_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
      "id_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},

      "title" => {"type" => "string", "minLength" => 1, "required" => true},

      "parent" => {"type" => "string", "required" => false, "pattern" => "/archival_objects/[0-9]+$"},
      "collection" => {"type" => "string", "required" => false, "pattern" => "/collections/[0-9]+$"},
    },

    "additionalProperties" => false,
  },
}
