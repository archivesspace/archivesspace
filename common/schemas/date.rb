{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "date_type" => {"type" => "string", "enum" => ["expression", "single", "bulk", "inclusive"], "required" => true},
      "label" => {"type" => "string", "enum" => ["broadcast", "copyright", "creation", "deaccession", "digitized", "issued", "modified", "publication", "other"], "required" => true},

      "uncertain" => {"type" => "string", "enum" => ["approximate", "inferred", "questionable"]},
      "expression" => {"type" => "string"},
      "begin" => {"type" => "string", "pattern" => "^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$"},
      "begin_time" => {"type" => "string", "pattern" => "^(([0-1]?[0-9])|([2][0-3])):([0-5]?[0-9])(:([0-5]?[0-9]))?$"},
      "end" => {"type" => "string", "pattern" => "^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$"},
      "end_time" => {"type" => "string", "pattern" => "^(([0-1]?[0-9])|([2][0-3])):([0-5]?[0-9])(:([0-5]?[0-9]))?$"},
      "era" => {"type" => "string", "enum" => ["ce"]},
      "calendar" => {"type" => "string", "enum" => ["gregorian"]},
    },

    "additionalProperties" => false,
  },
}
