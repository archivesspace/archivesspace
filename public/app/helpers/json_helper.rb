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
      notes_hash[type] ||= []
      notes_hash[type] << note_struct
    end

    notes_hash
  end

  def merge_notes(note_1, note_2)
    if note_1['label'].blank?
      # Our first label
      note_1['label'] = note_2['label']
    elsif note_1['label'] != note_2['label']
      # Add a secondary label as an inline label
      note_2_text = "<span class='inline-label'>#{note_2['label']}</span> #{note_2['note_text']}"
    end

    note_1['note_text'] = "#{note_1['note_text']}<br/><br/> #{note_2_text}"

    if note_2.has_key?('subnotes')
      note_1['subnotes'] ||= []
      note_1['subnotes'] = note_1['subnotes'] + note_2['subnotes'].map {|sub|
        sub_copy = sub.clone
        sub_copy['_inline_label'] = note_2['label']
        sub_copy
      }
    end

    note_1
  end

  private

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
    exp = date['expression'] || ''
    if exp.blank?
      exp = date['begin'] unless date['begin'].blank?
      unless date['end'].blank?
        exp = (exp.blank? ? '' : exp + ' - ') + date['end']
      end
    end
    if date['date_type'] == 'bulk'
      exp = exp.sub('bulk', '').sub('()', '').strip
      exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
              I18n.t('bulk._plural', :dates => exp)
    end

    [label, exp]
  end
end
