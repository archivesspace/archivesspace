{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "parent" => "external_document",
    "type" => "object",
    "properties" => {
      "identifier_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "rights_statement_external_document_identifier_type"},
    },
  },
}
