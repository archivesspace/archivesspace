{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/batch_imports",
    "properties" => {
      "batch" => {"type" => "array",
                  "items" => {"type" => [{"type" => "JSONModel(:resource) object"},
                                         {"type" => "JSONModel(:archival_object) object"},
                                         {"type" => "JSONModel(:accession) object"},
                                         {"type" => "JSONModel(:subject) object"},
                                         {"type" => "JSONModel(:agent_corporate_entity) object"},
                                         {"type" => "JSONModel(:agent_person) object"},
                                         {"type" => "JSONModel(:agent_family) object"},
                                         {"type" => "JSONModel(:digital_object) object"},
                                         {"type" => "JSONModel(:collection_management) object"},
                                         {"type" => "JSONModel(:event) object"},
                                         {"type" => "JSONModel(:term) object"}           
                                         ]},
                                       }
    },
    "additionalProperties" => false,
  },
}
