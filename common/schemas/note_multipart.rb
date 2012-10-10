{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "parent" => "abstract_note",

    "properties" => {

      "type" => {
        "type" => "string",
        "required" => true,
        "enum" => [
                   "Accruals",
                   "Appraisal",
                   "Arrangement",
                   "Biographical / Historical ",
                   "Conditions Governing Access",
                   "Conditions Governing Use",
                   "Custodial History",
                   "Dimensions",
                   "Existence and Location of Copies",
                   "Existence and Location of Originals",
                   "File Plan",
                   "General",
                   "Immediate Source of Acquisition",
                   "Legal Status",
                   "Other Finding Aids",
                   "Physical Characteristics and Technical Requirements",
                   "Preferred Citation",
                   "Processing Information",
                   "Related Archival Materials",
                   "Scope and Contents",
                   "Separated Materials"]
      },

      "subnotes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_chronology) object"},
                               {"type" => "JSONModel(:note_index) object"},
                               {"type" => "JSONModel(:note_orderedlist) object"},
                               {"type" => "JSONModel(:note_definedlist) object"}]},
      },
    },

    "additionalProperties" => false,
  },
}
