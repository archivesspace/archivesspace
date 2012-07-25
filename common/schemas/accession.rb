{
  "type" => "object",
  "properties" => {
    "accession_id_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
    "accession_id_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
    "accession_id_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
    "accession_id_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
    "title" => {"type" => "string", "required" => true},
    "content_description" => {"type" => "string", "required" => true},
    "condition_description" => {"type" => "string", "required" => true},

    "accession_date" => {type => "string", "required" => true}
  },

  "additionalProperties" => false
}
