{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_archival_object",
    "uri" => "/repositories/:repo_id/resources",
    "properties" => {

      "id_0" => {"type" => "string", "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_1" => {"type" => "string", "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_2" => {"type" => "string", "pattern" => "^[a-zA-Z0-9 ]*$"},
      "id_3" => {"type" => "string", "pattern" => "^[a-zA-Z0-9 ]*$"},

      "level" => {"type" => "string", "ifmissing" => "error", "enum" => ["class", "collection", "file", "fonds", "item", "otherlevel", "recordgrp", "series", "subfonds", "subgrp", "subseries"]},
      "other_level" => {"type" => "string"},
      
      "language" => {"ifmissing" => "error"},

      "publish" => {"type" => "boolean", "default" => true},
      "restrictions" => {"type" => "boolean", "default" => false},

      "repository_processing_note" => {"type" => "string"},
      "container_summary" => {"type" => "string"},

      "ead_id" => {"type" => "string"},
      "ead_location" => {"type" => "string"},

      # Finding aid
      "finding_aid_title" => {"type" => "string"},
      "finding_aid_filing_title" => {"type" => "string"},
      "finding_aid_date" => {"type" => "string"},
      "finding_aid_author" => {"type" => "string"},
      "finding_aid_description_rules" => {"type" => "string", "enum" => ["aacr", "cco", "dacs", "rad", "isadg"]},
      "finding_aid_language" => {"type" => "string"},
      "finding_aid_sponsor" => {"type" => "string"},
      "finding_aid_edition_statement" => {"type" => "string"},
      "finding_aid_series_statement" => {"type" => "string"},
      "finding_aid_revision_date" => {"type" => "string"},
      "finding_aid_revision_description" => {"type" => "string"},
      "finding_aid_status" => {"type" => "string", "enum" => ["completed", "in_progress", "under_revision", "unprocessed"]},
      "finding_aid_note" => {"type" => "string"},

      # Extents (overrides abstract schema)
      "extents" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:extent) object"}},

      "instances" => {"type" => "array", "items" => {"type" => "JSONModel(:instance) object"}},
      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "related_accession" => {"type" => "JSONModel(:accession) uri"},
      
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
