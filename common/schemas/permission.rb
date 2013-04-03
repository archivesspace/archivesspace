{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/permissions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "permission_code" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error", "minLength" => 1},
      "description" => {"type" => "string", "maxLength" => 32672, "ifmissing" => "error", "minLength" => 1},
      "level" => {"type" => "string", "ifmissing" => "error", "enum" => ["repository", "global"]},
    },

    "additionalProperties" => false,
  },
}
