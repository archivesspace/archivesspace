{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "query" => {"type" => ["JSONModel(:boolean_query) object", "JSONModel(:field_query) object", "JSONModel(:date_field_query) object", "JSONModel(:boolean_field_query) object"]},

    },
  },
}
