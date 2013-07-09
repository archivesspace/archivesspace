{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "date_type" => {"type" => "string", "dynamic_enum" => "date_type", "ifmissing" => "error"},
      "label" => {"type" => "string", "dynamic_enum" => "date_label", "ifmissing" => "error"},

      "certainty" => {"type" => "string", "dynamic_enum" => "date_certainty"},
      "expression" => {"type" => "string", "maxLength" => 255},
      "begin" => {"type" => "string", "maxLength" => 255},
      "end" => {"type" => "string", "maxLength" => 255},
      "era" => {"type" => "string", "dynamic_enum" => "date_era"},
      "calendar" => {"type" => "string", "dynamic_enum" => "date_calendar"},
    },
  },
}
