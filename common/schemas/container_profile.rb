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

      "dimension_units" => {"type" => "string", "ifmissing" => "error",  "dynamic_enum" => "dimension_units"},
      "extent_dimension" => {"type" => "string","ifmissing" => "error", "enum" => ["height", "width", "depth"]},

      "height" => {"type" => "string",  "ifmissing" => "error"},
      "width" => {"type" => "string",  "ifmissing" => "error"},
      "depth" => {"type" => "string",  "ifmissing" => "error"},

      "stacking_limit" => {"type" => "string", "required" => false},

      "display_string" => {"type" => "string", "readonly" => true},
    },
  },
}
