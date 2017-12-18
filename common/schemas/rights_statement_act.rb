{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "act_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "rights_statement_act_type"},
      "restriction" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "rights_statement_act_restriction"},
      "start_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
      "end_date" => {"type" => "date", "required" => false},

      "notes" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:note_rights_statement_act) object"},
      },
    },
  },
}
