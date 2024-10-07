class NotesHandler < Handler
  @@ao_note_types = {}
  @@do_note_types = {}

  def initialize
    if @@ao_note_types.empty?
      @@ao_note_types = ao_note_types
    end
    if @@do_note_types.empty?
      @@do_note_types = do_note_types
    end
  end

  def ao_note_types
    note_types = bib_note
    JSONModel.enum_values(JSONModel(:note_singlepart).schema["properties"]["type"]["dynamic_enum"]).each do |type|
      note_types[type] = {
        :target => :note_singlepart,
        :enum => JSONModel(:note_singlepart).schema["properties"]["type"]["dynamic_enum"],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_singlepart).schema["properties"]["type"]["dynamic_enum"]}.#{type}", :default => type),
      }
    end
    JSONModel.enum_values(JSONModel(:note_multipart).schema["properties"]["type"]["dynamic_enum"]).each do |type|
      note_types[type] = {
        :target => :note_multipart,
        :enum => JSONModel(:note_multipart).schema["properties"]["type"]["dynamic_enum"],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_multipart).schema["properties"]["type"]["dynamic_enum"]}.#{type}", :default => type),
      }
    end
    note_types
  end

  def bib_note
    note_types = {
      "bibliography" => {
        :target => :note_bibliography,
        :value => "bibliography",
        :i18n => I18n.t("enumerations._note_types.bibliography", :default => "bibliography"),
      },
    }
    note_types
  end

  def create_note(type, note_label, content, publish, dig_obj = false, b_date = nil, e_date = nil, local_restriction = nil)
    note_types = dig_obj ? @@do_note_types : @@ao_note_types
    note_type = note_types[type]
    if note_type.nil?
      raise BulkImportException.new(I18n.t("bulk_import.error.bad_note_type", :type => type))
    end
    note = JSONModel(note_type[:target]).new
    unless (note_label = note_label.to_s.strip).empty?
      note.label = note_label
    end
    note.publish = publish
    note.type = note_type[:value]
    begin
      wellformed(content)
    rescue Exception => e
      raise BulkImportException.new(I18n.t("bulk_import.error.bad_note", :type => note_type[:value], :msg => e.message))
    end
    # if the target is multipart, then the data goes in a JSONMODEL(:note_text).content;, which is pushed to the note.subnote array; otherwise it's just pushed to the note.content array
    if note_type[:target] == :note_multipart
      inner_note = JSONModel(:note_text).new
      inner_note.content = content
      inner_note.publish = publish
      note.subnotes.push inner_note
    else
      note.content.push content
    end

    unless local_restriction.nil?
      note.rights_restriction = {
        'local_access_restriction_type' => [local_restriction].compact,
      }
    end

    unless b_date.nil?
      note.rights_restriction = {} if note.rights_restriction.nil?

      note.rights_restriction['begin'] = b_date
    end

    unless e_date.nil?
      note.rights_restriction = {} if note.rights_restriction.nil?

      note.rights_restriction['end'] = e_date
    end

    # For some reason, just having the JSONModel doesn't work; convert to hash
    note.to_hash
  end

  def do_note_types
    note_types = bib_note
    # Digital object/digital object component
    JSONModel.enum_values(JSONModel(:note_digital_object).schema["properties"]["type"]["dynamic_enum"]).each do |type|
      note_types[type] = {
        :target => :note_digital_object,
        :enum => JSONModel(:note_digital_object).schema["properties"]["type"]["dynamic_enum"],
        :value => type,
        :i18n => I18n.t("enumerations.#{JSONModel(:note_digital_object).schema["properties"]["type"]["dynamic_enum"]}.#{type}", :default => type),
      }
    end
    note_types
  end

  def wellformed(note)
    if note.match("</?[a-zA-Z]+>")
      frag = Nokogiri::XML("<root xmlns:xlink='https://www.w3.org/1999/xlink'>#{note}</root>") { |config| config.strict }
    end
  end
end
