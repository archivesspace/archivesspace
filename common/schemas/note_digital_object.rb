{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => ["summary",
                   "bioghist",
                   "accessrestrict",
                   "userestrict",
                   "custodhist",
                   "dimensions",
                   "edition",
                   "extent",
                   "altformavail",
                   "originalsloc",
                   "note",
                   "acqinfo",
                   "inscription",
                   "langmaterial",
                   "legalstatus",
                   "physdesc",
                   "prefercite",
                   "processinfo",
                   "relatedmaterial"]
      },
    },

    "additionalProperties" => false,
  },
}
