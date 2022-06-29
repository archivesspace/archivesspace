{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "maintenance_event_type" => {
        "type" => "string",
        "dynamic_enum" => "maintenance_event_type",
        "ifmissing" => "error"
      },
      "maintenance_agent_type" => {
        "type" => "string",
        "dynamic_enum" => "maintenance_agent_type",
        "ifmissing" => "error",
        "default" => "Human"
      },
      "event_date" => {"type" => "date-time", "ifmissing" => "error"},
      "agent" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error"},
      "descriptive_note" => {"type" => "string", "maxLength" => 65000, "default" => ""},
    }
  }
}
