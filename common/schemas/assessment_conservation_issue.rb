{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "issue_type" => {"type" => "string", "dynamic_enum" => "assessment_conservation_issue_type", "ifmissing" => "error"},
      "issue_note" => {"type" => "string", "ifmissing" => "error"},

    },
  },
}
