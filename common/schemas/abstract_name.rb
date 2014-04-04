# Note: This schema isn't used directly: it's here for inheritance purposes
# only.
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "authority_id" => {"type" => "string", "maxLength" => 255},
      "dates" => {"type" => "string", "maxLength" => 255},
      "use_dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "qualifier" => {"type" => "string", "maxLength" => 255},
      "source" => {"type" => "string", "dynamic_enum" => "name_source"},
      "rules" => {"type" => "string", "dynamic_enum" => "name_rule"},

      "authorized" => {"type" => "boolean", "default" => false},
      "is_display_name" => {"type" => "boolean", "default" => false},

      "sort_name" => {"type" => "string", "maxLength" => 255},
      "sort_name_auto_generate" => {"type" => "boolean", "default" => true},
    },
  },
}
