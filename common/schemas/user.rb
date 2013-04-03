{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/users",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "username" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "name" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},

      "permissions" => {
        "type" => "object",
        "readonly" => true,
      },
      
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
      }
    },

    "additionalProperties" => false,
  },
}
