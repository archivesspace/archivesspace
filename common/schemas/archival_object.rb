{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "id_0" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
      "id_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
      "id_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},

      "title" => {"type" => "string", "minLength" => 1, "required" => true},

      "parent" => {"type" => "JSONModel(:archival_object) uri", "required" => false},
      "collection" => {"type" => "JSONModel(:collection) uri", "required" => false},

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
    },

    "additionalProperties" => false,
  },
}
