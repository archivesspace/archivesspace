{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "identifier" => {"type" => "string", "readonly" => true},
      "file_uri" => {"type" => "string", "maxLength" => 16384, "ifmissing" => "error"},
      "publish" => {"type" => "boolean"},
      "use_statement" => {"type" => "string", "dynamic_enum" => "file_version_use_statement"},

      "xlink_actuate_attribute" => {"type" => "string", "dynamic_enum" => "file_version_xlink_actuate_attribute"},

      "xlink_show_attribute" => {"type" => "string", "dynamic_enum" => "file_version_xlink_show_attribute"},


      "file_format_name" => {"type" => "string", "dynamic_enum" => "file_version_file_format_name"},
      "file_format_version" => {"type" => "string", "maxLength" => 255},
      "file_size_bytes" => {"type" => "integer"},
      "is_representative" => {"type" => "boolean", "default" => false},

      "checksum" => {"type" => "string", "maxLength" => 255},
      "checksum_method" => {"type" => "string", "dynamic_enum" => "file_version_checksum_methods"},
      "caption" => {"type" => "string", "maxLength" => 16384},
      "derived_from" => {"type" => [{"type" => "JSONModel(:digital_object) uri"},
                                    {"type" => "JSONModel(:digital_object_component) uri"}],
                         "readonly" => true},
      "link_uri" => {"type" => "string", "maxLength" => 16384, "readonly" => true},
    },
  },
}
