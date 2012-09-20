{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/groups",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "group_code" => {"type" => "string", "ifmissing" => "error", "minLength" => 1},
      "description" => {"type" => "string", "ifmissing" => "error", "default" => ""},

      "member_usernames" => {"type" => "array", "items" => {"type" => "string", "minLength" => 1}},
      "grants_permissions" => {"type" => "array", "items" => {"type" => "string", "minLength" => 1}},
    },

    "additionalProperties" => false,
  },
}
