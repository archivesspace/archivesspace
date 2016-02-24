# -*- coding: utf-8 -*-
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/container_profiles",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      
      "name" => {"type" => "string", "ifmissing" => "error"},
      "url" => {"type" => "string", "required" => false},

      "dimension_units" => {"type" => "string", "required" => false,  "dynamic_enum" => "dimension_units"},
      "extent_dimension" => {"type" => "string", "required" => false, "enum" => ["height", "width", "depth"]},

      "height" => {"type" => "string", "required" => false},
      "width" => {"type" => "string", "required" => false},
      "depth" => {"type" => "string", "required" => false},

      "display_string" => {"type" => "string", "readonly" => true},
    },
  },
}
