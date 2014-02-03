 {
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "children" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:digital_object_component) object"}
      },

    },
  },
}
