{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "description" => {"type" => "string", "maxLength" => 65000},
      "dates" => {"type" => "JSONModel(:date) object"}
    }
  }
}
