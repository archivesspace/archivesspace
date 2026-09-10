require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Making OAI repository sets and sponsor sets repeatable")

    now = Time.now

    create_table(:oai_repository_set) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      foreign_key :oai_config_id, :oai_config, :null => false

      String :set_name, :null => false, :unique => true
      TextField :set_description, :null => true
      TextField :repo_codes, :null => true

      apply_mtime_columns
    end

    create_table(:oai_sponsor_set) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      foreign_key :oai_config_id, :oai_config, :null => false

      String :set_name, :null => false, :unique => true
      TextField :set_description, :null => true
      TextField :sponsor_names, :null => true

      apply_mtime_columns
    end

    level_enum_id = self[:enumeration].filter(:name => 'archival_record_level').get(:id)
    level_values = level_enum_id ? self[:enumeration_value].filter(:enumeration_id => level_enum_id).select_map(:value) : []

    warn_if_shadowed = lambda do |set_name|
      next unless level_values.include?(set_name)

      $stderr.puts("WARNING: OAI set '#{set_name}' shares its name with a level of description. " \
                   "It will not be harvestable until it is renamed in the staff interface.")
    end

    self[:oai_config].each do |oai_config|
      set_defaults = {
        :oai_config_id       => oai_config[:id],
        :json_schema_version => 1,
        :created_by          => 'admin',
        :last_modified_by    => 'admin',
        :create_time         => now,
        :system_mtime        => now,
        :user_mtime          => now
      }

      repo_codes = oai_config[:repo_set_codes]

      if !oai_config[:repo_set_name].nil? && !repo_codes.nil? && !['', '[]'].include?(repo_codes)
        warn_if_shadowed.call(oai_config[:repo_set_name])

        self[:oai_repository_set].insert(set_defaults.merge(:set_name        => oai_config[:repo_set_name],
                                                            :set_description => oai_config[:repo_set_description],
                                                            :repo_codes      => repo_codes))
      end

      sponsor_names = oai_config[:sponsor_set_names]

      if !oai_config[:sponsor_set_name].nil? && !sponsor_names.nil? && !['', '[]'].include?(sponsor_names)
        warn_if_shadowed.call(oai_config[:sponsor_set_name])

        self[:oai_sponsor_set].insert(set_defaults.merge(:set_name        => oai_config[:sponsor_set_name],
                                                         :set_description => oai_config[:sponsor_set_description],
                                                         :sponsor_names   => sponsor_names))
      end
    end

    alter_table(:oai_config) do
      drop_column(:repo_set_codes)
      drop_column(:repo_set_description)
      drop_column(:repo_set_name)
      drop_column(:sponsor_set_names)
      drop_column(:sponsor_set_description)
      drop_column(:sponsor_set_name)
    end
  end
end
