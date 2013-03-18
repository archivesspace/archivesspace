{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "xlink" => {
        "type" => "object",
        "properties" => {
          "actuate" => {"type" => "string"},
          "arcrole" => {"type" => "string"},
          "href" => {"type" => "string"},
          "role" => {"type" => "string"},
          "show" => {"type" => "string"},
          "title" => {"type" => "string"},
          "type" => {"type" => "string"}, 
        }
      }

    },

    "additionalProperties" => false,
  },
}
