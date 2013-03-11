{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "query" => {"type" => ["JSONModel(:boolean_query) object", "JSONModel(:field_query) object"]},

    },

    "additionalProperties" => false,
  },
}
