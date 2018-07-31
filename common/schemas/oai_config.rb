{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/oai_config",

    "properties" => {
      "oai_record_prefix" => {"type" => "string", "required" => true},
      "oai_admin_email" => {"type" => "string", "required" => true},
      "oai_repository_name" => {"type" => "string", "required" => true}
    },
  },
}
