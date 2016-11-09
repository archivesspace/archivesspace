module JsonHelper
  #process the entire notes structure.  If req is specified, process and return only the notes that
  #  match the requested type (may be nil)
  def process_json_notes(notes, req = nil)
   notes_hash = {}
    if !notes.blank?
      if notes.kind_of?(Array)
        notes.each do |note|
          type = note['type']
          if (!req || type == req) && note['publish']
            set_up_note(notes_hash, type, note)
          end
        end
      else
        type = notes['type']
        if !req || type == req
          set_up_note(notes_hash, type, note)
        end
      end
    end
    notes_hash
  end


  # pull the note out of the result['json']['html'] hash, if it exists
  def get_note(json, type, deflabel='')
    note_struct = {}
    if json['html'].present? && json['html'].has_key?(type)
      note_struct = json['html'][type]
    end
# Pry::ColorPrinter.pp note_struct
    note_struct
  end

  private
  # handle possible multiple notes of same kind
  def set_up_note(notes_hash, type, note)
    note_struct = handle_note_structure(note, type)
    if notes_hash.has_key? type
      if notes_hash[type]['label'].blank?
        notes_hash[type]['label'] = note_struct['label'] 
      elsif notes_hash[type]['label'] != note_struct['label']
        #add a secondary label as an inline label
        note_struct['note_text']= "<span class='inline-label'>#{note_struct['label']}</span> #{note_struct['note_text']}"
      end
      notes_hash[type]['note_text'] = "#{notes_hash[type]['note_text']} #{note_struct['note_text']}"
    else
      notes_hash[type] = note_struct
    end
  end



  def handle_note_structure(note, type)
    note_struct = {}
    note_text = ''
    if note['publish'] || defined?(AppConfig[:ignore_false])  # temporary switch due to ingest issues
      label = note.has_key?('label') ? note['label'] :  I18n.t("enumerations._note_types.#{type}", :default => '')
      note_struct['label'] = label
#      note_text = "#{note_text} <span class='inline-label'>#{label}:</span>" if !label.blank?
      if note['jsonmodel_type'] == 'note_multipart' || !note['subnotes'].blank?
        note['subnotes'].each do |sub|
          note_text = handle_single_note(sub, note_text)
        end
      else
        note_text = handle_single_note(note, note_text)
      end
    end
    note_struct['note_text'] = note_text
    note_struct
  end
  
  def handle_single_note(note, input_note_text)
    note_text = input_note_text
    if  note['jsonmodel_type'] == 'note_orderedlist' && !note['items'].blank?
      txt = note['items'].join("</li><li>")
      note_text = add_contents("<ul class='no-bullets'><li>#{txt}</li></ul>", note_text)
    else
      if note['content'].kind_of?(Array)
        note['content'].each do |txt|
          note_text = add_contents(txt, note_text)
        end
      else
        note_text = add_contents(note['content'], note_text)
      end
    end

    note_text
  end

  def add_contents(contents, final_text)
     final_text = "#{final_text} <p>#{ process_mixed_content(contents)}</p>"
  end

end
