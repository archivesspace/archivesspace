module JsonHelper

  def get_note(json, type)
    note_txt = ''
    if !json['notes'].blank?
      json['notes'].each do |note|
        if note.has_key?('type') && note['type'] == type 
          note_txt = "<span class='inline-label'>#{note['label']}:</span>" if note_txt.blank? && !note['label'].blank? 
          if note['jsonmodel_type'] == 'note_multipart'
            note['subnotes'].each do |sub|
              if sub['publish']
                note_txt = add_contents(sub['content'], note_txt)
              end
            end
          else 
            if note['publish']
              note['content'].each do |txt|
                note_txt = add_contents(txt, note_txt)
              end
            end
          end
        end
      end
    end
    return note_txt
  end

  def add_contents(contents, final_text)
      final_text = "#{final_text} <p>#{ process_mixed_content(contents)}</p>"
  end

end
