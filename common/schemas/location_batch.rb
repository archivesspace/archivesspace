{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "source_location" => {"type" => "JSONModel(:location) object", "ifmissing" => "error"},

      "coordinate_1" => {
        "type" => "object",
        "ifmissing" => "error",
        "properties" => {
          "label" => {"type" => "string", "ifmissing" => "error"},
          "start" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "end" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "prefix" => {"type" => "string"},
          "suffix" => {"type" => "string"},
        }
      },

      "coordinate_2" => {
        "type" => "object",
        "properties" => {
          "label" => {"type" => "string", "ifmissing" => "error"},
          "start" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "end" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "prefix" => {"type" => "string"},
          "suffix" => {"type" => "string"},
        }
      },

      "coordinate_3" => {
        "type" => "object",
        "properties" => {
          "label" => {"type" => "string", "ifmissing" => "error"},
          "start" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "end" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "prefix" => {"type" => "string"},
          "suffix" => {"type" => "string"},
        }
      },

      "result_locations" => {"type" => "array", "items" => {"type" => "JSONModel(:location) uri_or_object"}}

    },

    "additionalProperties" => false,
  },
}
