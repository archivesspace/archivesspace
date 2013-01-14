{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/permissions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false, "readonly" => true},

      "permission_code" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
      "description" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
      "level" => {"type" => "string", "ifmissing" => "error", "enum" => ["repository", "global"]},
    },

    "additionalProperties" => false,
  },
}
