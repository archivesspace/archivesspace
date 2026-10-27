{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "caption" => {"type" => "string"},
      "image_url" => {"type" => "string"},
      "link_url" => {"type" => "string"},
      "record_uri" => {"type" => "string"},
      "digital_object_type" => {"type" => "string"},
      # The images to show, in turn, when the browser cannot display the image above (ANW-3089)
      "fallbacks" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "caption" => {"type" => "string"},
            "image_url" => {"type" => "string"},
            "record_uri" => {"type" => "string"},
            "digital_object_type" => {"type" => "string"},
          },
        },
      },
    },
  },
}
