# -*- coding: utf-8 -*-
{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/custom_report_templates",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      
      "name" => {"type" => "string", "ifmissing" => "error"},
      "description" => {"type" => "string", "maxLength" => 255},
      "data" => {"type" => "string", "ifmissing" => "error", "maxLength" => 65000}
    },
  },
}
