{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/users",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "username" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9\\-_.]+$"},
      "name" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},

      "permissions" => {
        "type" => "object",
        "readonly" => true,
      }
    },

    "additionalProperties" => false,
  },
}
