{
  :schema => {
    "type" => "object",
    "properties" => {
      "accession_id" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9_]*$"},
      "title" => {"type" => "string", "minLength" => 1, "required" => true},
      "content_description" => {"type" => "string", "required" => true},
      "condition_description" => {"type" => "string", "required" => true},

      "accession_date" => {type => "string", "minLength" => 1, "required" => true}
    },

    "additionalProperties" => false,
  },

  :extra_properties => ["accession_id_0", "accession_id_1",
                        "accession_id_2", "accession_id_3"],

  :hooks => {
    :from_hash => Proc.new do |hash|
      if hash.has_key?("accession_id_0")
        hash["accession_id"] = IDUtils::a_to_s((0..3).map {|i| hash["accession_id_#{i}"]})

        (0..3).each do |i|
          hash.delete("accession_id_#{i}")
        end
      end

      hash
    end
  }
}
