
class NotesHandler < Handler
    @@ao_note_types = {}
    @@do_note_types = {}

    def self.ao_note_types
        note_types = bib_note
        JSONModel.enum_values(JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']).each do |type|
             note_types[type] = {
               :target => :note_singlepart,
               :enum => JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum'],
               :value => type,
               :i18n => I18n.t("enumerations.#{JSONModel(:note_singlepart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
             }
        end
        JSONModel.enum_values(JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']).each do |type|
             note_types[type] = {
              :target => :note_multipart,
              :enum => JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum'],
              :value => type,
              :i18n => I18n.t("enumerations.#{JSONModel(:note_multipart).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
             }
        end
        note_types
  end
   
  def self.bib_note
      note_types = {
        "bibliography" => {
          :target => :note_bibliography,
          :value => "bibliography",
          :i18n => I18n.t("enumerations._note_types.bibliography", :default => "bibliography")
        }
      }
      note_types
  end
  def self.create_notes(row, publish, report, dig_obj = false)
    notes = []
    note_types = dig_obj ? @@do_note_types : @@ao_note_types
    notes_keys = @row_hash.keys.grep(/^n_/)
    notes_keys.each do |key|
      content = @row_hash[key]
      type = key.match(/n_(.+)$/)[1]
      note_type = note_types[type]
      note = JSONModel(note_type[:target]).new
      pubnote = @row_hash["p_#{type}"]
      if pubnote.nil?
        pubnote = publish
      else
        pubnote = (pubnote == '1')
      end
      note.publish = pubnote
      note.type = note_type[:value]
      begin 
        wellformed(content)
# if the target is multipart, then the data goes in a JSONMODEL(:note_text).content;, which is pushed to the note.subnote array; otherwise it's just pushed to the note.content array
        if note_type[:target] == :note_multipart
          inner_note = JSONModel(:note_text).new
          inner_note.content = content
          inner_note.publish = pubnote
          note.subnotes.push inner_note
        else
          note.content.push content
        end
        notes.push note
      rescue Exception => e
        report.add_errors(I18n.t('bulk_import.error.bad_note', :type => note_type[:value] , :msg => CGI::escapeHTML( e.message)))
      end
    end
    notes
  end

  def self.do_note_types
    note_types = bib_note
    # Digital object/digital object component
    JSONModel.enum_values(JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum']).each do |type|
      note_types[type] = {
        :target => :note_digital_object,
        :enum => JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum'],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_digital_object).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
      }
    end
    note_types
  end

  
  def self.init
    if @@ao_note_types.empty?
      @@ao_note_types = self.ao_note_types
    end
    if @@do_note_types.empty?
      @@do_note_types = self.do_note_types
    end
  end
  def self.wellformed(note)
    if note.match("</?[a-zA-Z]+>")
      frag = Nokogiri::XML("<root xmlns:xlink='https://www.w3.org/1999/xlink'>#{note}</root>") {|config| config.strict}
    end
  end
end