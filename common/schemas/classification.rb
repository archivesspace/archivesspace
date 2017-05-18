{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_classification",
    "uri" => "/repositories/:repo_id/classifications",
    "properties" => {

      "has_classification_terms" => {"type" => "boolean", "readonly" => true},

    },
  },
}
