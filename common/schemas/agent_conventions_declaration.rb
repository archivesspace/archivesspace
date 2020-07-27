{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "name_rule" => {
        "type" => "string",
        "dynamic_enum" => "name_rule",
        "required" => "false"
      },
      "citation" => {"type" => "string", "maxLength" => 65000, "required" => false},
      "descriptive_note" => {"type" => "string", "maxLength" => 65000, "default" => ""},
      "file_uri" => {"type" => "string", "maxLength" => 65000},
      "file_version_xlink_actuate_attribute" => {
        "type" => "string",
        "dynamic_enum" => "file_version_xlink_actuate_attribute",
        "required" => false
      },
      "file_version_xlink_show_attribute" => {
        "type" => "string", 
        "dynamic_enum" => "file_version_xlink_show_attribute",
        "required" => false
      },
      "xlink_title_attribute" => {"type" => "string", "maxLength" => 65000},
      "xlink_role_attribute" => {"type" => "string", "maxLength" => 65000},
      "xlink_arcrole_attribute" => {"type" => "string", "maxLength" => 65000},
      "last_verified_date" => {"type" => "date-time"},
      "id"                        => {"type" => "integer", "required" => false},
      "agent_person_id"           => {"type" => "integer", "required" => false},
      "agent_family_id"           => {"type" => "integer", "required" => false},
      "agent_corporate_entity_id" => {"type" => "integer", "required" => false},
      "agent_software_id"         => {"type" => "integer", "required" => false}
    }
  }
}
