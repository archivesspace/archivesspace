{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {

      "report_type" => { 
        "type" => "string",
        "ifmissing" => "error"
      }, 
      
      "format" => { 
        "type" => "string",
        "ifmissing" => "error"
      } 
      

    }
  }
}
