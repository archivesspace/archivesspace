{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_classification",
    "uri" => "/repositories/:repo_id/classifications",
    "properties" => {
      "titles" => {"type" => "array", "ifmissing" => "error", "minItems" => 1, "items" => {"type" => "JSONModel(:title) object"}},

      "has_classification_terms" => {"type" => "boolean", "readonly" => true},
      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true}

    },
  },
}
