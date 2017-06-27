{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "material_type" => {"type" => "string", "dynamic_enum" => "assessment_material_type", "ifmissing" => "error"},
      "material_note" => {"type" => "string", "ifmissing" => "error"},
      "special_format_note" => {"type" => "string"},
      "exhibition_value_note" => {"type" => "string"},

    },
  },
}
