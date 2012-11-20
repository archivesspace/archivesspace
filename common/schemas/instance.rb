{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "instance_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "enum" => ["audio", "books", "computer_disks", "graphic_materials", "maps", "microform", "mixed_materials", "moving_images", "realia", "text"]},

      "container" => {"type" => "JSONModel(:container) object"},
    },

    "additionalProperties" => false,
  },
}
