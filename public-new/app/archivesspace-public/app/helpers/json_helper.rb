module JsonHelper

  def get_note(json, type, deflabel='')
    note_text = ''
    if !json['notes'].blank?
      if json['notes'].kind_of?(Array)
        json['notes'].each do |note|
           if note['publish'] || defined?(AppConfig[:ignore_false])  # temporary switch due to ingest issues
             if note.has_key?('type') && note['type'] == type
               label = note['label'].blank? ? deflabel : note['label']
               note_text = "#{note_text} <span class='inline-label'>#{label}:</span>" if !label.blank?
               if note['jsonmodel_type'] == 'note_multipart'
                 note['subnotes'].each do |sub|
                  note_text = handle_single_note(sub, note_text)
                end
               else
                 note_text = handle_single_note(note, note_text)
               end
             end
           end
        end
      end
    end
    note_text
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
