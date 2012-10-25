{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_objects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "digital_object_id" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "level" => {"type" => "string", "enum" => ["collection", "work", "image"]},
      "title" => {"type" => "string"},
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
      "language" => {"type" => "string"},
      "restrictions" => {"type" => "boolean", "default" => false},
      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
      "extents" => {"type" => "array", "required" => true, "minItems" => 1, "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

    },

    "additionalProperties" => false
  },
}
