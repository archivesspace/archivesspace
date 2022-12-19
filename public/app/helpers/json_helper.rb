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
    label_value = date.fetch('label', date['date_label'])
    begin_date  = date.fetch('begin', date.fetch('structured_date_range', {})['begin_date_standardized'])
    end_date    = date.fetch('end',   date.fetch('structured_date_range', {})['end_date_standardized'])

    if !label_value.blank?
      if label_value == 'creation'
        label = ''
      else
        label = "#{I18n.t('enumerations.date_label.' + label_value)}: "
      end
    else
      label = ''
    end

    exp = date['expression'] || ''
    if exp.blank?
      exp = begin_date unless begin_date.blank?
      unless end_date.blank?
        exp = (exp.blank? ? '' : exp + ' - ') + end_date
      end
    end

    if date['date_type'] == 'bulk'
      exp = exp.sub('bulk', '').sub('()', '').strip
      exp = begin_date == end_date ? I18n.t('bulk._singular', :dates => exp) :
              I18n.t('bulk._plural', :dates => exp)
    end

    [label, exp, label_value]
  end
end
