{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => ["Abstract",
                   "General Physical Description",
                   "Language of Materials",
                   "Location",
                   "Materials Specific Details ",
                   "Physical Facet"]
      },
    },

    "additionalProperties" => false,
  },
}
