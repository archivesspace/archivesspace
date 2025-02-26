{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "type" => {"type" => "string", "dynamic_enum" => "title_type"},
      "language" => {"type" => "string", "dynamic_enum" => "language_iso639_2"},
      "script" => {"type" => "string", "dynamic_enum" => "script_iso15924"}
    }
  }
}
