{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/users",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "username" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},

      "is_system_user" => {"type" => "boolean", "readonly" => true},

      "permissions" => {
        "type" => "object",
        "readonly" => true,
      },

      "groups" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:group) uri"
        }
      },

      "email" => {"type" => "string", "maxLength" => 255},
      "first_name" => {"type" => "string", "maxLength" => 255},
      "last_name" => {"type" => "string", "maxLength" => 255},
      "telephone" => {"type" => "string", "maxLength" => 255},
      "title" => {"type" => "string", "maxLength" => 255},
      "department" => {"type" => "string", "maxLength" => 255},
      "additional_contact" => {"type" => "string", "maxLength" => 65000},

      "agent_record" => {
        "type" => "object",
        "readonly" => true,
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:agent_person) uri"}, {"type" => "JSONModel(:agent_software) uri"}]
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
      },

      "is_active_user" => {"type" => "boolean", "default" => true, "readonly" => true},

      "is_admin" => {
        "type" => "boolean",
        "default" => false
      }
    },
  },
}
