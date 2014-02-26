{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "label" => {"type" => "string", "maxLength" => 65000},
      "publish" => {"type" => "boolean"},
      "persistent_id" => {"type" => "string", "maxLength" => 255},
      "ingest_problem" => {"type" => "string", "maxLength" => 65000},
    },
  },
}
