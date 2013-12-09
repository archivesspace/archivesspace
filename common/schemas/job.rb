{
    :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "version" => 1,
        "type" => "object",
        "uri" => "/jobs",
        "properties" => {
            "uri" => {"type" => "string", "required" => false},

            "filenames" => {
                "type" => "array",
                "items" => {
                    "type" => "string",
                }
            },

            "import_type" => {
                "type" => "string",
                "enum" => ["ead_xml", "marcxml", "marcxml_subjects_and_agents", "accession_csv", "digital_object_csv"]
            }
        },
    },
}
