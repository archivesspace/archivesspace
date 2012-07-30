{
  :schema => {
    "type" => "object",
    "properties" => {
      "id" => {"type" => "string", "minLength" => 1, "required" => true},
      "title" => {"type" => "string", "minLength" => 1},
      "level" => {"type" => "string", "minLength" => 1},
      "wraps" => {"type" => "array", 
                    "minItems" => 1, 
                    "uniqueItems" => true, 
                    "description" => "Array of IDs of objects nested within this one",
                    "items" => { "type" => "string", "minLength" => 1 } 
                    },
      "wrapped_by" => {"type" => "string", "description" =>"id of the object wrapping this one"}
    },

    "additionalProperties" => false,
  },
}
