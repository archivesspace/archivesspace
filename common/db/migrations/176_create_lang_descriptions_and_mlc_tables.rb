require_relative 'utils'

Sequel.migration do
  up do
    create_table(:language_and_script_of_description) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false
      Integer :is_primary, :default => 0
      DynamicEnum :language_id, :null => false
      DynamicEnum :script_id,   :null => false
      Integer :resource_id,                 :null => true
      Integer :accession_id,                :null => true
      Integer :archival_object_id,          :null => true
      Integer :digital_object_id,           :null => true
      Integer :digital_object_component_id, :null => true
      apply_mtime_columns
    end
    alter_table(:language_and_script_of_description) do
      add_foreign_key([:resource_id],                 :resource,                 :key => :id)
      add_foreign_key([:accession_id],                :accession,                :key => :id)
      add_foreign_key([:archival_object_id],          :archival_object,          :key => :id)
      add_foreign_key([:digital_object_id],           :digital_object,           :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

    create_table(:resource_mlc) do
      Integer     :resource_id, :null => false
      DynamicEnum :language_id, :null => false
      DynamicEnum :script_id,   :null => false
      TextField :title
      TextField :finding_aid_title
      TextField :finding_aid_subtitle
      TextField :finding_aid_author
      TextField :finding_aid_sponsor
      TextField :finding_aid_edition_statement
      TextField :finding_aid_series_statement
      TextField :finding_aid_note
      TextField :repository_processing_note
      TextField :finding_aid_filing_title
      primary_key [:resource_id, :language_id, :script_id]
    end
    alter_table(:resource_mlc) do
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    create_table(:accession_mlc) do
      Integer     :accession_id, :null => false
      DynamicEnum :language_id,  :null => false
      DynamicEnum :script_id,    :null => false
      TextField :title
      TextField :content_description
      TextField :condition_description
      TextField :disposition
      TextField :inventory
      TextField :provenance
      TextField :general_note
      TextField :access_restrictions_note
      TextField :use_restrictions_note
      primary_key [:accession_id, :language_id, :script_id]
    end
    alter_table(:accession_mlc) do
      add_foreign_key([:accession_id], :accession, :key => :id)
    end

    create_table(:archival_object_mlc) do
      Integer     :archival_object_id, :null => false
      DynamicEnum :language_id,        :null => false
      DynamicEnum :script_id,          :null => false
      TextField :title
      primary_key [:archival_object_id, :language_id, :script_id]
    end
    alter_table(:archival_object_mlc) do
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end

    create_table(:digital_object_mlc) do
      Integer     :digital_object_id, :null => false
      DynamicEnum :language_id,       :null => false
      DynamicEnum :script_id,         :null => false
      TextField :title
      primary_key [:digital_object_id, :language_id, :script_id]
    end
    alter_table(:digital_object_mlc) do
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end

    create_table(:digital_object_component_mlc) do
      Integer     :digital_object_component_id, :null => false
      DynamicEnum :language_id,                 :null => false
      DynamicEnum :script_id,                   :null => false
      TextField :title
      TextField :label
      primary_key [:digital_object_component_id, :language_id, :script_id]
    end
    alter_table(:digital_object_component_mlc) do
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

    # --- Data migration: move existing field values to _mlc tables ---
    # Default to English (eng) + Latin (Latn)

    lang_enum   = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
    script_enum = self[:enumeration].filter(:name => 'script_iso15924').get(:id)
    eng_id  = self[:enumeration_value].filter(:enumeration_id => lang_enum,   :value => 'eng').get(:id)
    latn_id = self[:enumeration_value].filter(:enumeration_id => script_enum, :value => 'Latn').get(:id)

    {
      :resource => %i[title finding_aid_title finding_aid_subtitle finding_aid_author
                      finding_aid_sponsor finding_aid_edition_statement
                      finding_aid_series_statement finding_aid_note
                      repository_processing_note finding_aid_filing_title],
      :accession => %i[title content_description condition_description disposition
                       inventory provenance general_note
                       access_restrictions_note use_restrictions_note],
      :archival_object          => %i[title],
      :digital_object           => %i[title],
      :digital_object_component => %i[title label],
    }.each do |record_type, fields|
      mlc_table = :"#{record_type}_mlc"
      fk        = :"#{record_type}_id"
      self[record_type].each do |row|
        self[mlc_table].insert(
          fk           => row[:id],
          :language_id => eng_id,
          :script_id   => latn_id,
          **fields.each_with_object({}) { |f, h| h[f] = row[f] }
        )
      end
    end

    alter_table(:resource) do
      drop_column :title
      drop_column :finding_aid_title
      drop_column :finding_aid_subtitle
      drop_column :finding_aid_author
      drop_column :finding_aid_sponsor
      drop_column :finding_aid_edition_statement
      drop_column :finding_aid_series_statement
      drop_column :finding_aid_note
      drop_column :repository_processing_note
      drop_column :finding_aid_filing_title
    end

    alter_table(:accession) do
      drop_column :title
      drop_column :content_description
      drop_column :condition_description
      drop_column :disposition
      drop_column :inventory
      drop_column :provenance
      drop_column :general_note
      drop_column :access_restrictions_note
      drop_column :use_restrictions_note
    end

    alter_table(:archival_object) do
      drop_column :title
    end

    alter_table(:digital_object) do
      drop_column :title
    end

    alter_table(:digital_object_component) do
      drop_column :title
      drop_column :label
    end
  end
end
