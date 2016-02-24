class Accession < JSONModel(:accession)
  attr_accessor :resource_link

  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end
  
  def ref_id
    ref_id = ""
    
    (0..3).each do |i|
      next if self.send("id_#{i.to_s}").blank?
      ref_id << " - " unless i === 0
      ref_id << self.send("id_#{i.to_s}")
    end
    
    ref_id
  end


  def populate_from_accession(accession)
    values = accession.to_hash(:raw)

    # Recursively remove bits that don't make sense to copy (like "lock_version" properties)
    values = JSONSchemaUtils.map_hash_with_schema(values, JSONModel(:accession).schema,
                                                  [proc { |hash, schema|
                                                          hash = hash.clone
                                                     hash.delete_if {|k, v| k.to_s =~ /^(id_[0-9]|lock_version)$/}
                                                          hash
                                                   }])

    prepare_for_clone(values)

    self.update(values)
  end


  private

  def prepare_for_clone(values)
    values.delete('linked_events')
    values.delete('external_ids')
    values.delete('related_accessions')
    values.delete('related_resources')
    values.delete('external_documents')
    values.delete('rights_statements')
    values.delete('instances')
    values.delete('deaccessions')
    values.delete('collection_management')
    values.delete('classification')
  end

end
