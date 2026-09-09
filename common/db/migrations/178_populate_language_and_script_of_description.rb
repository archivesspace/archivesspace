require_relative 'utils'

Sequel.migration do
  up do
    lang_enum   = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
    script_enum = self[:enumeration].filter(:name => 'script_iso15924').get(:id)

    default_lang_id   = self[:enumeration_value].filter(:enumeration_id => lang_enum,   :value => AppConfig[:mlc_default_language]).get(:id)
    default_script_id = self[:enumeration_value].filter(:enumeration_id => script_enum, :value => AppConfig[:mlc_default_script]).get(:id)

    raise "language_iso639_2 enum value '#{AppConfig[:mlc_default_language]}' not found" if default_lang_id.nil?
    raise "script_iso15924 enum value '#{AppConfig[:mlc_default_script]}' not found" if default_script_id.nil?

    now = Time.now

    # resource: finding_aid_language_id/finding_aid_script_id are copied as-is.
    # These columns are never NULL due to migration 121, so AppConfig
    # defaults are never needed here.
    self[:resource].select(:id, :finding_aid_language_id, :finding_aid_script_id).each do |row|
      self[:language_and_script_of_description].insert(
        :resource_id => row[:id],
        :language_id => row[:finding_aid_language_id],
        :script_id   => row[:finding_aid_script_id],
        :is_primary  => 1,
        :json_schema_version => 1,
        :create_time => now,
        :system_mtime => now,
        :user_mtime => now
      )
    end

    # accession: language_id and script_id are independent, optional fields.
    # Each defaults to the AppConfig value only when NULL. Existing values
    # are never discarded.
    self[:accession].select(:id, :language_id, :script_id).each do |row|
      language_id = row[:language_id] || default_lang_id
      script_id   = row[:script_id] || default_script_id

      self[:language_and_script_of_description].insert(
        :accession_id => row[:id],
        :language_id  => language_id,
        :script_id    => script_id,
        :is_primary   => 1,
        :json_schema_version => 1,
        :create_time => now,
        :system_mtime => now,
        :user_mtime => now
      )
    end

    # digital_object: no language-of-description equivalent exists,
    # so always take the configured MLC defaults.
    self[:digital_object].select(:id).each do |row|
      self[:language_and_script_of_description].insert(
        :digital_object_id => row[:id],
        :language_id => default_lang_id,
        :script_id   => default_script_id,
        :is_primary  => 1,
        :json_schema_version => 1,
        :create_time => now,
        :system_mtime => now,
        :user_mtime => now
      )
    end
  end
end
