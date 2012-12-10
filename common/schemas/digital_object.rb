{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/digital_objects",
    "properties" => {

      "digital_object_id" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "level" => {"type" => "string", "enum" => ["collection", "work", "image"]},
      "digital_object_type" => {
        "type" => "string",
        "enum" => [
                   "cartographic",
                   "mixed_materials",
                   "moving_image",
                   "notated_music",
                   "software_multimedia",
                   "sound_recording",
                   "sound_recording_musical",
                   "sound_recording_nonmusical",
                   "still_image",
                   "text"
                  ]
      },

      "restrictions" => {"type" => "boolean", "default" => false},

      "notes" => {
            "type" => "array",
            "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                                   {"type" => "JSONModel(:note_digital_object) object"}]},
          },

    },

    "additionalProperties" => false
  },
}
