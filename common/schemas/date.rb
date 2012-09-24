{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "type" => {"type" => "string", "enum" => ["single", "bulk", "inclusive"], "required" => true},
      "label" => {"type" => "string", "enum" => ["broadcast", "copyright", "creation", "deaccession", "digitized", "issued", "modified", "publication", "other"], "required" => true},

      "uncertain" => {"type" => "string", "enum" => ["approximate", "inferred", "questionable"]},
      "expression" => {"type" => "string"},
      "begin" => {"type" => "string"},
      "begin_time" => {"type" => "string"},
      "end" => {"type" => "string"},
      "end_time" => {"type" => "string"},
      "era" => {"type" => "string", "enum" => ["ce"]},
      "calendar" => {"type" => "string", "enum" => ["gregorian"]},
    },

  },
}
