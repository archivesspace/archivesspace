{
  "type" => "object",
  "properties" => {
    "accession_id_0" => {"type" => "string", "required" => true},
    "accession_id_1" => {"type" => "string", "required" => true},
    "accession_id_2" => {"type" => "string", "required" => true},
    "accession_id_3" => {"type" => "string", "required" => true},
    "title" => {"type" => "string", "required" => true},
    "content_description" => {"type" => "string", "required" => true},
    "condition_description" => {"type" => "string", "required" => true},

    "nested" => {
      "type" => "object",
      "required" => true,
      "additionalProperties" => false,
      "properties" => {
        "hello" => {"type" => "string", "required" => true},
      }},

    "accession_date" => {type => "string", "format" => "date", "required" => true}
  },

  "additionalProperties" => false
}
