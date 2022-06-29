{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "relationship_uri" => {"type" => "string", "required" => false},
      "specific_relator" => {
        "type" => "string",
        "dynamic_enum" => "agent_relationship_specific_relator"
      },
      "description" => {"type" => "string", "maxLength" => 65000},
      "dates" => {"type" => "JSONModel(:structured_date_label) object"}
    }
  }
}
