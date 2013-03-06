{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "op" => {"type" => "string", "enum" => ["AND", "OR", "NOT"], "ifmissing" => "error"},
      "subqueries" => {"type" => ["JSONModel(:boolean_query) object", "JSONModel(:field_query) object"]},

    },

    "additionalProperties" => false,
  },
}
