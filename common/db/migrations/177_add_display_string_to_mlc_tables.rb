require_relative 'utils'

Sequel.migration do
  up do
    # --- Add display_string to the MLC tables that need it ---

    [:accession_mlc, :archival_object_mlc, :digital_object_component_mlc].each do |mlc_table|
      alter_table(mlc_table) do
        add_column :display_string, :text
      end
    end

    # --- Migrate existing display_string values from main tables into the
    #     MLC rows already created by migration 176 (eng/Latn defaults) ---

    lang_enum   = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
    script_enum = self[:enumeration].filter(:name => 'script_iso15924').get(:id)
    eng_id   = self[:enumeration_value].filter(:enumeration_id => lang_enum,   :value => AppConfig[:mlc_default_language]).get(:id)
    latn_id  = self[:enumeration_value].filter(:enumeration_id => script_enum, :value => AppConfig[:mlc_default_script]).get(:id)

    {
      :accession                => :accession_mlc,
      :archival_object          => :archival_object_mlc,
      :digital_object_component => :digital_object_component_mlc,
    }.each do |main_table, mlc_table|
      fk = :"#{main_table}_id"
      self[main_table].select(:id, :display_string).each do |row|
        self[mlc_table]
          .filter(fk => row[:id], :language_id => eng_id, :script_id => latn_id)
          .update(:display_string => row[:display_string])
      end
    end

    # --- Drop display_string from main tables ---

    alter_table(:accession) do
      drop_column :display_string
    end

    alter_table(:archival_object) do
      drop_column :display_string
    end

    alter_table(:digital_object_component) do
      drop_column :display_string
    end
  end
end
