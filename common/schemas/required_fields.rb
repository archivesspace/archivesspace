{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/required_fields/:record_type",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "record_type" => {"type" => "string", "ifmissing" => "error", "enum" => ['archival_object', 'digital_object_component', 'resource', 'accession', 'subject', 'digital_object', 'agent_person', 'agent_family', 'agent_software', 'agent_corporate_entity', 'event', 'location', 'classification', 'classification_term']},
      "required" => {"type" => "object"},
    },
  },
}