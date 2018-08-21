{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/oai_config",

    "properties" => {
      "oai_record_prefix" => {"type" => "string", "required" => true},
      "oai_admin_email" => {"type" => "string", "required" => true},
      "oai_repository_name" => {"type" => "string", "required" => true},
      "repo_set_codes" => {"type" => "string"},
      "sponsor_set_names" => {"type" => "string"},
      "repo_set_description" => {"type" => "string"},
      "sponsor_set_description" => {"type" => "string"},
      "repo_set_name" => {"type" => "string"},
      "sponsor_set_name" => {"type" => "string"}
    },
  },
}
