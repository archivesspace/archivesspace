class LangHandler < Handler
    @@language_types = CvList.new('language_iso639_2')
    @@script_types = CvList.new('script_iso15924')

    def self.renew
        clear(@@language_types)
        clear(@@script_types)
    end

    # special method to determine if we can deal with language blocks
    def self.ead3
      return @@language_types.length > 0
    end

    def self.create_language(row, substr,publish, report)
        langs = []
        have_lang = !row["l_lang#{substr}"].blank?
        have_note = !row["n_langmaterial#{substr}"].blank?
        if have_lang || have_note
          lang_val = have_lang ? row["l_lang#{substr}"] : row["n_langmaterial#{substr}"]
          begin
            lang_code = @@language_types.value(lang_val)
          rescue Exception => n
            report.add_errors( I18n.t('plugins.aspace-import-excel.error.lang_code', :lang => lang_val))
            return langs  # stop right there!
          end
          langscript = JSONModel(:language_and_script).new
          langscript.language = lang_code
          if !row["l_langscript#{substr}"].blank?
            begin
              langscript.script = @@script_types.value(row["l_langscript#{substr}"])
            rescue => exception
                report.add_errors( I18n.t('plugins.aspace-import-excel.error.lang_code', :script => row["l_langscript#{substr}"]))
            end
          end
          lang = JSONModel(:lang_material).new
          lang.language_and_script = langscript
          langs.push lang
          if have_lang && have_note
            lang = JSONModel(:lang_material).new
            pub = row["p_langmaterial#{substr}"]
            pub = pub.blank? ? publish : (pub == '1')
            content = row["n_langmaterial#{substr}"]
            begin
              wellformed(content)
              note = JSONModel(:note_langmaterial).new
              note.publish = publish
              note.type = 'langmaterial'
              note.content.push content if !content.nil?
              lang.notes.push note
            rescue Exception => e
              report.add_errors(I18n.t('plugins.aspace-import-excel.error.bad_note', :type => 'langmaterial' , :msg => CGI::escapeHTML( e.message)))
            end
            langs.push lang            
          end
          langs
        end   
    end
    # currently a repeat from the controller
    def self.wellformed(note)
      if note.match("</?[a-zA-Z]+>")
        frag = Nokogiri::XML("<root xmlns:xlink='https://www.w3.org/1999/xlink'>#{note}</root>") {|config| config.strict}
      end
    end
end