{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "content" => {
        "type" => "array",
        "items" => {"type" => "string", "maxLength" => 65000},
        "minItems" => 1,
        "ifmissing" => "error",
      },

      "xlink" => {
        "type" => "object",
        "properties" => {
          "actuate" => {"type" => "string", "maxLength" => 65000},
          "arcrole" => {"type" => "string", "maxLength" => 65000},
          "href" => {"type" => "string", "maxLength" => 65000},
          "role" => {"type" => "string", "maxLength" => 65000},
          "show" => {"type" => "string", "maxLength" => 65000},
          "title" => {"type" => "string", "maxLength" => 16384},
          "type" => {"type" => "string", "maxLength" => 65000},
        }
      }

    },
  },
}
