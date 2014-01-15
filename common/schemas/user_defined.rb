{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "boolean_1" => {"type" => "boolean", "default" => false},
      "boolean_2" => {"type" => "boolean", "default" => false},
      "boolean_3" => {"type" => "boolean", "default" => false},

      "integer_1" => {"type" => "string", "maxlength" => 255, "required" => false},
      "integer_2" => {"type" => "string", "maxlength" => 255, "required" => false},
      "integer_3" => {"type" => "string", "maxlength" => 255, "required" => false},

      "real_1" => {"type" => "string", "maxlength" => 13, "required" => false},
      "real_2" => {"type" => "string", "maxlength" => 13, "required" => false},
      "real_3" => {"type" => "string", "maxlength" => 13, "required" => false},

      "string_1" => {"type" => "string", "maxLength" => 255, "required" => false},
      "string_2" => {"type" => "string", "maxLength" => 255, "required" => false},
      "string_3" => {"type" => "string", "maxLength" => 255, "required" => false},
      "string_4" => {"type" => "string", "maxLength" => 255, "required" => false},

      "text_1" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_2" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_3" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_4" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "text_5" => {"type" => "string", "maxLength" => 65000, "required" => false},

      "date_1" => {"type" => "date", "required" => false},
      "date_2" => {"type" => "date", "required" => false},
      "date_3" => {"type" => "date", "required" => false},

      "enum_1" => {"type" => "string", "dynamic_enum" => "user_defined_enum_1"},
      "enum_2" => {"type" => "string", "dynamic_enum" => "user_defined_enum_2"},
      "enum_3" => {"type" => "string", "dynamic_enum" => "user_defined_enum_3"},
      "enum_4" => {"type" => "string", "dynamic_enum" => "user_defined_enum_4"},
    },
  },
}
