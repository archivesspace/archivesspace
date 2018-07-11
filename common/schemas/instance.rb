{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "instance_type" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "instance_instance_type"},

      "sub_container" => {"type" => "JSONModel(:sub_container) object"},

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

      "is_representative" => {"type" => "boolean", "default" => false},
    },
  },
}
