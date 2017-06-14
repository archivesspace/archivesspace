module JsonHelper

  # process the entire notes structure.  If req is specified, process and return only the notes that
  #  match the requested types (may be nil)
  def process_json_notes(notes, req = nil)
    notes_hash = {}
    ASUtils.wrap(notes).each do |note|
      type = note['type'] || note['jsonmodel_type']

      next unless !req || req.include?(type)
      next unless note['publish']

      note_struct = handle_note_structure(note, type)
      merge_notes_by_type(notes_hash, type, note_struct)
    end

    notes_hash
  end


  private

  # Called for each note we parse, loading each note into `notes_hash`.
  #
  # `notes_hash` ends up being a mapping of note types to a merged version of
  # all of the notes of that type.
  def merge_notes_by_type(notes_hash, type, note_struct)
    # If we haven't seen a note of this type yet, just take the first one
    if !notes_hash.has_key? type
      notes_hash[type] = note_struct
      return
    end

    # Otherwise, do a merge
    if notes_hash[type]['label'].blank?
      # Our first label
      notes_hash[type]['label'] = note_struct['label']
    elsif notes_hash[type]['label'] != note_struct['label']
      # Add a secondary label as an inline label
      note_struct['note_text']= "<span class='inline-label'>#{note_struct['label']}</span> #{note_struct['note_text']}"
    end

    notes_hash[type]['note_text'] = "#{notes_hash[type]['note_text']}<br/><br/> #{note_struct['note_text']}"

    if note_struct.has_key?('subnotes')
      notes_hash[type]['subnotes'] ||= []
      notes_hash[type]['subnotes'] = notes_hash[type]['subnotes'] + note_struct['subnotes'].map{|sub|
        sub['_inline_label'] = note_struct['label']
        sub
      }
    end
  end


  def handle_note_structure(note, type)
    return nil unless note['publish'] || defined?(AppConfig[:pui_ignore_false])  # temporary switch due to ingest issues

    renderer = NoteRenderer.for(note['jsonmodel_type'])

    note_struct = {}
    note_struct['is_inherited'] = note['_inherited']

    renderer.render(type, note, note_struct)

    note_struct
  end

  def parse_date(date)
    label = date['label'].blank? ? '' : "#{date['label'].titlecase}: "
    label = '' if label == 'Creation: '
    exp =  date['expression'] || ''
    if exp.blank?
      exp = date['begin'] unless date['begin'].blank?
      unless date['end'].blank?
        exp = (exp.blank? ? '' : exp + ' - ') + date['end']
      end
    end
    if date['date_type'] == 'bulk'
      exp = exp.sub('bulk','').sub('()', '').strip
      exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
              I18n.t('bulk._plural', :dates => exp)
    end

    [label, exp]
  end
end
