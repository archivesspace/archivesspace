{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {
      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "enum" => [
                   "Summary",
                   "Biographical / Historical",
                   "Conditions Governing Access",
                   "Conditions Governing Use",
                   "Custodial History",
                   "Dimensions",
                   "Edition",
                   "Extent",
                   "Existence and Location of Copies",
                   "Existence and Location of Originals",
                   "General Note",
                   "Immediate Source of Acquisition",
                   "Inscription",
                   "Language of Materials",
                   "Legal Status",
                   "Physical Description",
                   "Preferred Citation",
                   "Processing Information",
                   "Related Materials",
                  ]
      },
    },

    "additionalProperties" => false,
  },
}
