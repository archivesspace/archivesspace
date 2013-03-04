{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => ["accruals",
                   "appraisal",
                   "arrangement",
                   "bioghist",
                   "accessrestrict",
                   "userestrict",
                   "custodhist",
                   "dimensions",
                   "altformavail",
                   "originalsloc",
                   "fileplan",
                   "odd",
                   "acqinfo",
                   "legalstatus",
                   "otherfindaid",
                   "phystech",
                   "prefercite",
                   "processinfo",
                   "relatedmaterial",
                   "scopecontent",
                   "separatedmaterial"]
      },

      "subnotes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_chronology) object"},
                               {"type" => "JSONModel(:note_orderedlist) object"},
                               {"type" => "JSONModel(:note_definedlist) object"}]},
      },
    },

    "additionalProperties" => false,
  },
}
