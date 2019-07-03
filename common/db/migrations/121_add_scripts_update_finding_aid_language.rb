require_relative 'utils'
require 'nokogiri'

Sequel.migration do
  up do

    # If finding_aid_language_note contains encoded <language> tags with valid langcode and/or scriptcode create a finding_aid_language and/or finding_aid_script
    def migrate_language_notes(dataset)

      dataset.each do |row|

        note = self[:resource].filter(:id => row[:id]).get(:finding_aid_language_note)
        parsed = Nokogiri::XML::DocumentFragment.parse(note)
        language = parsed.xpath('.//language').attr('langcode')
        if !language.nil?
          enum = self[:enumeration].filter(:name => 'language_iso639_2').select(:id)
          langcode = self[:enumeration_value].filter(:value => language.value, :enumeration_id => enum ).select(:id)
          self[:resource].filter(:id => row[:id]).update(:finding_aid_language_id => langcode)
        end
        script = parsed.xpath('.//language').attr('scriptcode')
        if !script.nil?
          enum = self[:enumeration].filter(:name => 'script_iso15924').select(:id)
          scriptcode = self[:enumeration_value].filter(:value => script.value, :enumeration_id => enum ).select(:id)
          self[:resource].filter(:id => row[:id]).update(:finding_aid_script_id => scriptcode)
        end

        if note.match(/(<language langcode="[a-z]+" scriptcode="[A-z]+">(.*)<\/language>)|(<language langcode="[a-z]+">(.*)<\/language>)|(<language langcode="[a-z]+"\/>)/)
          content = note.sub(/(<language langcode="[a-z]+" scriptcode="[A-z]+">(.*)<\/language>)|(<language langcode="[a-z]+">(.*)<\/language>)|(<language langcode="[a-z]+"\/>)/, '\\2\\4')
          self[:resource].filter(:id => row[:id]).update(:finding_aid_language_note => content)
        end

      end
    end

    def set_blank_lang_to_default(dataset)
      lang_enum = self[:enumeration].filter(:name => 'language_iso639_2').select(:id)
      und_lang = self[:enumeration_value].filter(:value => 'und', :enumeration_id => lang_enum ).select(:id)

      dataset.each do |row|
        self[:resource].filter(:id => row[:id]).update(:finding_aid_language_id => und_lang)
      end
    end

    def set_blank_script_to_default(dataset)
      script_enum = self[:enumeration].filter(:name => 'script_iso15924').select(:id)
      und_script = self[:enumeration_value].filter(:value => 'Zyyy', :enumeration_id => script_enum ).select(:id)

      dataset.each do |row|
        self[:resource].filter(:id => row[:id]).update(:finding_aid_script_id => und_script)
      end
    end

    create_editable_enum('script_iso15924', ["Adlm", "Afak", "Aghb", "Ahom", "Arab", "Aran", "Armi", "Armn", "Avst", "Bali", "Bamu", "Bass", "Batk", "Beng", "Bhks", "Blis", "Bopo", "Brah", "Brai", "Bugi", "Buhd", "Cakm", "Cans", "Cari", "Cham", "Cher", "Cirt", "Copt", "Cpmn", "Cprt", "Cyrl", "Cyrs", "Deva", "Dogr", "Dsrt", "Dupl", "Egyd", "Egyh", "Egyp", "Elba", "Elym", "Ethi", "Geok", "Geor", "Glag", "Gong", "Gonm", "Goth", "Gran", "Grek", "Gujr", "Guru", "Hanb", "Hang", "Hani", "Hano", "Hans", "Hant", "Hatr", "Hebr", "Hira", "Hluw", "Hmng", "Hmnp", "Hrkt", "Hung", "Inds", "Ital", "Jamo", "Java", "Jpan", "Jurc", "Kali", "Kana", "Khar", "Khmr", "Khoj", "Kitl", "Kits", "Knda", "Kore", "Kpel", "Kthi", "Lana", "Laoo", "Latf", "Latg", "Latn", "Leke", "Lepc", "Limb", "Lina", "Linb", "Lisu", "Loma", "Lyci", "Lydi", "Mahj", "Maka", "Mand", "Mani", "Marc", "Maya", "Medf", "Mend", "Merc", "Mero", "Mlym", "Modi", "Mong", "Moon", "Mroo", "Mtei", "Mult", "Mymr", "Nand", "Narb", "Nbat", "Newa", "Nkdb", "Nkgb", "Nkoo", "Nshu", "Ogam", "Olck", "Orkh", "Orya", "Osge", "Osma", "Palm", "Pauc", "Perm", "Phag", "Phli", "Phlp", "Phlv", "Phnx", "Plrd", "Piqd", "Prti", "Qaaa", "Qabx", "Rjng", "Rohg", "Roro", "Runr", "Samr", "Sara", "Sarb", "Saur", "Sgnw", "Shaw", "Shrd", "Shui", "Sidd", "Sind", "Sinh", "Sogd", "Sogo", "Sora", "Soyo", "Sund", "Sylo", "Syrc", "Syre", "Syrj", "Syrn", "Tagb", "Takr", "Tale", "Talu", "Taml", "Tang", "Tavt", "Telu", "Teng", "Tfng", "Tglg", "Thaa", "Thai", "Tibt", "Tirh", "Ugar", "Vaii", "Visp", "Wara", "Wcho", "Wole", "Xpeo", "Xsux", "Yiii", "Zanb", "Zinh", "Zmth", "Zsye", "Zsym", "Zxxx", "Zyyy", "Zzzz"])

    # Update Language of Description columns
    alter_table(:resource) do
      rename_column(:finding_aid_language, :finding_aid_language_note)
      set_column_type(:finding_aid_language_note, 'varchar')
      add_column(:finding_aid_language_id, :integer, :null => true)
      add_column(:finding_aid_script_id, :integer, :null => true)
    end

    migrate_language_notes(self[:resource].filter(Sequel.like(:finding_aid_language_note, '%<language%')))

    # Set remaining blanks to default language and script
    set_blank_lang_to_default(self[:resource].where(finding_aid_language_id: nil))
    set_blank_script_to_default(self[:resource].where(finding_aid_script_id: nil))


  end
end
