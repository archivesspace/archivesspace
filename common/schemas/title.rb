{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "type" => {"type" => "string", "dynamic_enum" => "title_type"},
      "language_and_script" => {"type" => "JSONModel(:language_and_script) object"},
    }
  }
}
