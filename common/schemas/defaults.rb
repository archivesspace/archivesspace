{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "show_suppressed" =>  {"type" => "boolean", "required" => false},
      "publish" =>  {"type" => "boolean", "required" => false},
      "accession_browse_label_title" => {"type" => "string", "required" => false},
      "accession_browse_label_identifier" => {"type" => "string", "required" => false},

    },
  },
}
