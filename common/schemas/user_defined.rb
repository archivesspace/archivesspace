{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "boolean_1" => {"type" => "boolean", "default" => false},
      "boolean_2" => {"type" => "boolean", "default" => false},

      "integer_1" => {"type" => "string", "maxlength" => 255, "required" => false},
      "integer_2" => {"type" => "string", "maxlength" => 255, "required" => false},

      "real_1" => {"type" => "string", "maxlength" => 13, "required" => false},
      "real_2" => {"type" => "string", "maxlength" => 13, "required" => false},

      "string_1" => {"type" => "string", "maxLength" => 255, "required" => false},
      "string_2" => {"type" => "string", "maxLength" => 255, "required" => false},
      "string_3" => {"type" => "string", "maxLength" => 255, "required" => false},

      "text_1" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_2" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_3" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_4" => {"type" => "string", "maxLength" => 65000, "required" => false},
    },

    "additionalProperties" => false,
  },
}
