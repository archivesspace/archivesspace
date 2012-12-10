{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/archival_objects",
    "properties" => {
      "ref_id" => {"type" => "string", "pattern" => "^[a-zA-Z0-9]*$"},
      "component_id" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9_]*$"},

      "level" => {"type" => "string", "ifmissing" => "error", "enum" => ["class", "collection", "file", "fonds", "item", "otherlevel", "recordgrp", "series", "subfonds", "subgrp", "subseries"]},
      "other_level" => {"type" => "string"},

      "parent" => {"type" => "JSONModel(:archival_object) uri", "required" => false},
      "resource" => {"type" => "JSONModel(:resource) uri", "required" => false},
      "position" => {"type" => "integer", "required" => false},

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },
    },



    "additionalProperties" => false,
  },
}
