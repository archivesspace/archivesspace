# Note: This schema isn't used directly: it's here for inheritance purposes
# only.
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "authority_id" => {"type" => "string"},
      "dates" => {"type" => "string"},
      "description_type" => {"type" => "string", "dynamic_enum" => "name_description_type"},
      "description_note" => {"type" => "string"},
      "description_citation" => {"type" => "string"},
      "qualifier" => {"type" => "string"},
      "source" => {"type" => "string", "dynamic_enum" => "name_source"},
      "rules" => {"type" => "string", "dynamic_enum" => "name_rule"},

      "sort_name" => {"type" => "string"},
      "sort_name_auto_generate" => {"type" => "boolean", "default" => true},
    },
  },
}
