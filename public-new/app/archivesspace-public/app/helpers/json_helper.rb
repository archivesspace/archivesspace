module JsonHelper

  def get_note(json, type, deflabel='')
    note_txt = ''
    if !json['notes'].blank?
      if json['notes'].kind_of?(Array)
        json['notes'].each do |note|
           if note['publish'] || defined?(AppConfig[:ignore_false])  # temporary switch due to ingest issues
             if note.has_key?('type') && note['type'] == type
               label = note['label'].blank? ? deflabel : note['label']
               note_txt = "<span class='inline-label'>#{label}:</span>" if note_txt.blank? && !label.blank?
               if note['jsonmodel_type'] == 'note_multipart'
                 note['subnotes'].each do |sub|
                  note_txt = add_contents(sub['content'], note_txt)
                end
               elsif note['jsonmodel_type'] == 'note_orderedlist' && !note['items'].blank?
                 txt = note['items'].join("</li><li>")
                 note_text = "<ul><li>#{txt}</li></ul>"
               else
                 note['content'].each do |txt|
                  note_txt = add_contents(txt, note_txt)
                end
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
