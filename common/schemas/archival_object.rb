{
  :schema => {
    "type" => "object",
    "properties" => {
      "id" => {"type" => "string", "minLength" => 1, "required" => true},
      "title" => {"type" => "string", "minLength" => 1, "required" => true}
    },

    "additionalProperties" => false,
  },
}
