{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "type_1" => {"type" => "string", "minLength" => 1, "required" => true},
      "indicator_1" => {"type" => "string", "minLength" => 1, "required" => true},
      "barcode_1" => {"type" => "string", "minLength" => 1, "required" => true},

      "type_2" => {"type" => "string"},
      "indicator_2" => {"type" => "string"},

      "type_3" => {"type" => "string"},
      "indicator_3" => {"type" => "string"},
    },

    "additionalProperties" => false,
  },
}
