{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => ["abstract", "physdesc", "langmaterial", "physloc", "materialspec", "physfacet"]

      },
    },

    "additionalProperties" => false,
  },
}
