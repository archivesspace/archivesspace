{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "date_type" => {"type" => "string", "dynamic_enum" => "date_type"},
      "label" => {"type" => "string", "dynamic_enum" => "date_label", "ifmissing" => "error"},

      "certainty" => {"type" => "string", "dynamic_enum" => "date_certainty"},
      "expression" => {"type" => "string", "maxLength" => 255},
      "begin" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A-?([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)\\z"},
      "end" => {"type" => "string", "maxLength" => 255, "pattern" => "\\A-?([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)\\z"},
      "era" => {"type" => "string", "dynamic_enum" => "date_era"},
      "calendar" => {"type" => "string", "dynamic_enum" => "date_calendar"},
    },

    "additionalProperties" => false,
  },
}
