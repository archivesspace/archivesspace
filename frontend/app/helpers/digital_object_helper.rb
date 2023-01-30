# Maps desired resource/archival object/accession fields to new digital object instance fields as specified in ANW-1615
module DigitalObjectHelper

  def map_record_fields_to_digital_object(record)
    if ['resource', 'accession', 'archival_object'].include? record['jsonmodel_type']
      record_hash = (record.class == Hash ? record : record.to_hash)
    end

    if not record_hash
      raise ArgumentError.new("not a valid resource/accession/archival_object JSONModel or hash")
    end

    copy_fields = ['title', 'dates', 'lang_materials']
    processed_fields = record_hash.clone.keep_if {|k, v| copy_fields.include? k }

    cleanup!(processed_fields)

    # many resource note types will map exactly
    accept_resource_note_types = note_types_for('digital_object').keys
    # other note types will be mapped to a different digital object note type
    accept_resource_note_types.concat(['abstract', 'scopecontent', 'materialspec', 'physfacet', 'phystech', 'odd'])

    if record_hash['notes']
      new_notes = []
      record_hash['notes'].each do |note_record|
        if note_record['jsonmodel_type'] == 'note_bibliography'
          new_note = JSONModel(:note_bibliography)
            .from_hash(note_record.select {|k, v| ['content', 'publish'].include? k})
        else
          next unless accept_resource_note_types.include? note_record['type']
          new_note_h = {
            'publish'  => note_record['publish'],
            'content'  => case note_record['jsonmodel_type']
                          when 'note_singlepart'
                            note_record['content']
                          when 'note_multipart'
                            # DO notes are not multipart so just grab any note text and add them
                            # as content items (important to avoid the other complex types)
                            note_record['subnotes'].map { |sn|
                              sn['content'] if sn['jsonmodel_type'] == 'note_text'
                            }.compact
                          end,
            'type'     => case note_record['type']
                          when 'abstract', 'scopecontent'
                            'summary'
                          when 'materialspec', 'phystech', 'physfacet'
                            'physdesc'
                          when 'odd'
                            'note'
                          else
                            note_record['type']
                          end
          }

          # notes with no content are invalid!
          next unless new_note_h['content'].length > 0

          new_note = JSONModel(:note_digital_object).from_hash(new_note_h)
        end
        new_notes << new_note.to_hash
      end
      processed_fields['notes'] = new_notes
    end

    return processed_fields
  end

  private

  def cleanup!(data)
    if data.is_a? Array
      data.each {|item| cleanup!(item)}
    end
    if data.is_a? Hash
      delete_fields = ['lock_version', 'created_by', 'last_modified_by', 'create_time', 'system_mtime', 'user_mtime']
      data.delete_if {|k, v| delete_fields.include? k }
      data.each_value {|v| cleanup!(v)}
    end
  end

end
