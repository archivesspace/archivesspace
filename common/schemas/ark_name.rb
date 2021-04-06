{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/ark:/:naan/:ark_id",
    "properties" => {
      "resource_id"                 => {"type" => "integer", "required" => false},
      "archival_object_id"          => {"type" => "integer", "required" => false},
      }
  }
}
