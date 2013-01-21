{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "instance_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["audio", "books", "computer_disks", "digital_object","graphic_materials", "maps", "microform", "mixed_materials", "moving_images", "realia", "text"]},

      "container" => {"type" => "JSONModel(:container) object"},

      "digital_object" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => "JSONModel(:digital_object) uri",
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
    },

    "additionalProperties" => false,
  },
}
