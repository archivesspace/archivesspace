{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "scope" => {"type" => "string", "default" => "whole", "enum" => ["whole", "part"], "ifmissing" => "error"},
      "description" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error"},

      "reason" => {"type" => "string", "maxLength" => 255},
      "disposition" => {"type" => "string", "maxLength" => 255},
      "notification" => {"type" => "boolean", "default" => false},

      "date" => {"type" => "JSONModel(:date) object", "ifmissing" => "error"},

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
    },

    "additionalProperties" => false,
  },
}
