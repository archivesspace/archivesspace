{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "xlink" => {
        "type" => "object",
        "properties" => {
          "actuate" => {"type" => "string", "maxLength" => 32672},
          "arcrole" => {"type" => "string", "maxLength" => 32672},
          "href" => {"type" => "string", "maxLength" => 32672},
          "role" => {"type" => "string", "maxLength" => 32672},
          "show" => {"type" => "string", "maxLength" => 32672},
          "title" => {"type" => "string", "maxLength" => 32672},
          "type" => {"type" => "string", "maxLength" => 32672},
        }
      }

    },

    "additionalProperties" => false,
  },
}
