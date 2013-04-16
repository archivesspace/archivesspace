{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
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
