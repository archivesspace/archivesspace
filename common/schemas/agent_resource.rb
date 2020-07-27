{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "id" => {"type" => "integer", "required" => false},

      "linked_agent_role" => {"type" => "string", "dynamic_enum" => "linked_agent_role", "ifmissing" => "error", "required" => true},

      "linked_resource" => {"type" => "string", "maxLength" => 65000, "ifmissing" => "error", "required" => true},

      "linked_resource_description" => {"type" => "string", "maxLength" => 65000},

      "file_uri" => {"type" => "string", "maxLength" => 65000},

      "file_version_xlink_actuate_attribute" => {
        "type" => "string",
        "dynamic_enum" => "file_version_xlink_actuate_attribute",
        "required" => false
      },
      "file_version_xlink_show_attribute" => {
        "type" => "string", 
        "dynamic_enum" => "file_version_xlink_show_attribute",
        "required" => false
      },      

      "xlink_title_attribute" => {"type" => "string", "maxLength" => 65000},
      "xlink_role_attribute" => {"type" => "string", "maxLength" => 65000},
      "xlink_arcrole_attribute" => {"type" => "string", "maxLength" => 65000},
      "last_verified_date" => {"type" => "date-time"},
      
      "dates" => {
        "type" => "array",
        "items" => {"type" => "JSONModel(:structured_date_label) object"}
      },

      "places" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:subject) uri",
              "ifmissing" => "error"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      }
    },
  },
}