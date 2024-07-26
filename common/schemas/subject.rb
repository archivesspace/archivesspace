{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/subjects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "title" => {"type" => "string", "readonly" => true},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "is_linked_to_published_record" => {"type" => "boolean", "readonly" => true},

      "publish" => {"type" => "boolean", "default" => true, "readonly" => true},

      "slug" => {"type" => "string"},
      "is_slug_auto" => {"type" => "boolean", "default" => true},

      "used_within_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},
      "used_within_published_repositories" => {"type" => "array", "items" => {"type" => "JSONModel(:repository) uri"}, "readonly" => true},

      "source" => {"type" => "string", "dynamic_enum" => "subject_source", "ifmissing" => "error"},

      "scope_note" => {"type" => "string"},

      "terms" => {"type" => "array", "items" => {"type" => "JSONModel(:term) uri_or_object"}, "ifmissing" => "error", "minItems" => 1},

      "vocabulary" => {"type" => "JSONModel(:vocabulary) uri", "ifmissing" => "error"},
      "authority_id" => {"type" => "string", "maxLength" => 255},

      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

      "metadata_rights_declarations" => {"type" => "array", "items" => {"type" => "JSONModel(:metadata_rights_declaration) object"}},
    },
  },
}
