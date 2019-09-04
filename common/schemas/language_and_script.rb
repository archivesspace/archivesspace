{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

     "properties" => {
      "language" => {"type" => "string", "dynamic_enum" => "language_iso639_2", "ifmissing" => "error"},
      "script" => {"type" => "string", "dynamic_enum" => "script_iso15924"}
    },
  },
}
