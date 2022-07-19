class ArchivalObject < JSONModel(:archival_object)

  def populate_from_accession(accession)
    values = accession.to_hash(:raw)

    # Recursively remove bits that don't make sense to copy (like "lock_version"
    # properties)
    values = JSONSchemaUtils.map_hash_with_schema(values, JSONModel(:accession).schema,
                                                        [proc { |hash, schema|
                                                          hash = hash.clone
                                                          hash.delete_if {|k, v| k.to_s =~ /^(id_[0-9]|lock_version|instances|deaccessions|collection_management|user_defined|external_documents)$/}
                                                          hash
                                                        }])

    # We'll replace this with our own relationship, linking us back to the
    # accession we were spawned from.
    # values.delete('related_accessions')

    notes ||= []

    if accession.content_description
      notes << JSONModel(:note_multipart).from_hash(:type => "scopecontent",
                                                    :label => I18n.t('accession.content_description'),
                                                    :subnotes => [{
                                                                    'content' => accession.content_description,
                                                                    'jsonmodel_type' => 'note_text'
                                                                  }])
    end

    if accession.condition_description
      notes << JSONModel(:note_singlepart).from_hash(:type => "physdesc",
                                                     :label => I18n.t('accession.condition_description'),
                                                     :content => [accession.condition_description])
    end

    self.accession_links = [{'ref' => accession.uri, '_resolved' => accession}]

    self.notes = notes

    self.update(values)

    self.rights_statements = Array(accession.rights_statements).map {|rights_statement|
      rights_statement.clone.tap {|r| r.delete('identifier')}
    }
  end
end
