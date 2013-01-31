{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/batch_imports",
    "properties" => {
      "batch" => {"type" => "array",
                  "items" => {"type" => [{"type" => "JSONModel(:resource) object"},
                                         {"type" => "JSONModel(:archival_object) object"},
                                         {"type" => "JSONModel(:accession) object"},
                                         {"type" => "JSONModel(:subject) object"},
                                         {"type" => "JSONModel(:agent_corporate_entity) object"},
                                         {"type" => "JSONModel(:agent_person) object"},
                                         {"type" => "JSONModel(:collection_management) object"}                
                                         ]},
                                       }
    },
    "additionalProperties" => false,
  },
}