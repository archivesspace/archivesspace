{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/telephone",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "number" => {"type" => "string", "maxLength" => 65000},
      "ext" => {"type" => "string", "maxLength" => 65000},
      'number_type' => { 'type' => 'string', 'required' => false,  "dynamic_enum" => 'telephone_number_type' } 
    },
  },
}
