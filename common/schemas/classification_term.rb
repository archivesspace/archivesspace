{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_classification",
    "uri" => "/repositories/:repo_id/classification_terms",
    "properties" => {

      "position" => {"type" => "integer", "required" => false},

      "parent" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:classification_term) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        },
      },

      "classification" => {
        "type" => "object",
        "subtype" => "ref",
        "ifmissing" => "error",
        "properties" => {
          "ref" => {"type" => "JSONModel(:classification) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          },
        },
        "ifmissing" => "error"
      }
    },
  },
}
