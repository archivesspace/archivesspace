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

      "dimension_units" => {"type" => "string", "required" => true,  "dynamic_enum" => "dimension_units"},
      "extent_dimension" => {"type" => "string", "required" => true, "enum" => ["height", "width", "depth"]},

      "height" => {"type" => "string", "required" => true},
      "width" => {"type" => "string", "required" => true},
      "depth" => {"type" => "string", "required" => true},

      "display_string" => {"type" => "string", "readonly" => true},
    },
  },
}
