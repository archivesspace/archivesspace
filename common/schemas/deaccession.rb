{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {

      "whole_part" => {"type" => "boolean", "default" => true, "ifmissing" => "error"},
      "description" => {"type" => "string", "minLength" => 1, "ifmissing" => "error"},

      "reason" => {"type" => "string"},
      "disposition" => {"type" => "string"},
      "notification" => {"type" => "boolean", "default" => false},

      "date" => {"type" => "JSONModel(:date) object", "ifmissing" => "error"},

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
    },

    "additionalProperties" => false,
  },
}
