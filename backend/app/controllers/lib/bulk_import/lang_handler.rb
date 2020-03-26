class LangHandler < Handler
  def initialize(current_user)
    @language_types = CvList.new("language_iso639_2", current_user)
    @script_types = CvList.new("script_iso15924", current_user)
  end

  def renew
    clear(@language_types)
    clear(@script_types)
  end

  def create_language(lang_val, script, langmaterial, publish, report)
    langs = []
    have_lang = !lang_val.nil?
    have_note = !langmaterial.nil?
    if have_lang || have_note
      lang_code = nil
      if !have_lang
        begin
          lang_code = @language_types.value(langmaterial)
          have_note = false
        rescue Exception => n
          #we know that the note isn't just the language
        end
      else
        begin
          lang_code = @language_types.value(lang_val)
        rescue Exception => n
          report.add_errors(I18n.t("bulk_import.error.lang_code", :lang => lang_val))
        end
      end
      if lang_code
        langscript = JSONModel(:language_and_script).new
        langscript.language = lang_code
        if !script.nil?
          begin
            langscript.script = @script_types.value(script)
          rescue Exception => n
            report.add_errors(I18n.t("bulk_import.error.script_code", :script => script))
          end
        end
        lang = JSONModel(:lang_material).new
        lang.language_and_script = langscript
        langs.push lang
      end
      if have_note
        lang = JSONModel(:lang_material).new
        content = langmaterial
        begin
          wellformed(content)
          note = JSONModel(:note_langmaterial).new
          if publish.class.name == "String"
            publish = publish == "1"
          end
          note.publish = publish
          note.type = "langmaterial"
          note.content.push content if !content.nil?
          lang.notes.push note
          langs.push lang
        rescue Exception => e
          report.add_errors(I18n.t("bulk_import.error.bad_note", :type => "langmaterial", :msg => CGI::escapeHTML(e.message)))
        end
      end
    end
    langs
  end

  # currently a repeat from the controller
  def wellformed(note)
    if note.match("</?[a-zA-Z]+>")
      frag = Nokogiri::XML("<root xmlns:xlink='https://www.w3.org/1999/xlink'>#{note}</root>") { |config| config.strict }
    end
  end
end
