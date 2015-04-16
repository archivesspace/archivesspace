{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "location",
    "properties" => {

      "locations" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:location) uri"
        }
      },

      "coordinate_1_range" => {
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

      "coordinate_2_range" => {
        "type" => "object",
        "properties" => {
          "label" => {"type" => "string", "ifmissing" => "error"},
          "start" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "end" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "prefix" => {"type" => "string"},
          "suffix" => {"type" => "string"},
        }
      },

      "coordinate_3_range" => {
        "type" => "object",
        "properties" => {
          "label" => {"type" => "string", "ifmissing" => "error"},
          "start" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "end" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
          "prefix" => {"type" => "string"},
          "suffix" => {"type" => "string"},
        }
      }

    },
  },
}
