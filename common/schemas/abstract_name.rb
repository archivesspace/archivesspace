# Note: This schema isn't used directly: it's here for inheritance purposes
# only.
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "properties" => {
      "authority_id" => {"type" => "string"},
      "dates" => {"type" => "string"},
      "description_type" => {"type" => "string"},
      "description_note" => {"type" => "string"},
      "description_citation" => {"type" => "string"},
      "qualifier" => {"type" => "string"},
      "source" => {"type" => "string", "enum" => ["local", "naf", "nad", "ulan"]},
      "rules" => {"type" => "string", "enum" => ["local", "aacr", "dacs"]},
      "sort_name" => {"type" => "string", "ifmissing" => "error"},
    },
  },
}
