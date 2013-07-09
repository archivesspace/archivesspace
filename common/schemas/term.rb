{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/terms",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "term" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},
      "term_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "subject_term_type"},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"}
    },
  },
}
