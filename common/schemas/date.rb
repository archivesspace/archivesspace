{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",

    "properties" => {
      "date_type" => {"type" => "string", "enum" => ["single", "bulk", "inclusive"]},
      "label" => {"type" => "string", "enum" => ["broadcast", "copyright", "creation", "deaccession", "digitized", "issued", "modified", "publication", "other"], "ifmissing" => "error"},

      "certainty" => {"type" => "string", "enum" => ["approximate", "inferred", "questionable"]},
      "expression" => {"type" => "string", "maxLength" => 255},
      "begin" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)\\z"},
      "begin_time" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A(([0-1]?[0-9])|([2][0-3])):([0-5]?[0-9])(:([0-5]?[0-9]))?\\z"},
      "end" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)\\z"},
      "end_time" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A(([0-1]?[0-9])|([2][0-3])):([0-5]?[0-9])(:([0-5]?[0-9]))?\\z"},
      "era" => {"type" => "string", "dynamic_enum" => "date_era"},
      "calendar" => {"type" => "string", "dynamic_enum" => "date_calendar"},
    },

    "additionalProperties" => false,
  },
}
