require_relative 'utils'
require 'digest'
require 'json'

def delete_zombies
  # Resources
  zombies = self[:ark_name]
              .left_join(:resource, Sequel.qualify(:ark_name, :resource_id) => Sequel.qualify(:resource, :id))
              .filter(Sequel.~(Sequel.qualify(:ark_name, :resource_id) => nil))
              .filter(Sequel.qualify(:resource, :id) => nil)
              .select(Sequel.qualify(:ark_name, :id))
              .map {|row| row.fetch(:id)}

  self[:ark_name].filter(:id => zombies).delete

  # Archival Objects
  zombies = self[:ark_name]
              .left_join(:archival_object, Sequel.qualify(:ark_name, :archival_object_id) => Sequel.qualify(:archival_object, :id))
              .filter(Sequel.~(Sequel.qualify(:ark_name, :archival_object_id) => nil))
              .filter(Sequel.qualify(:archival_object, :id) => nil)
              .select(Sequel.qualify(:ark_name, :id))
              .map {|row| row.fetch(:id)}

  self[:ark_name].filter(:id => zombies).delete
end

def check_for_ambiguous_ark_links
  bad_records = []
  arks = self[:resource].group_and_count(:external_ark_url).having { count.function.* > 1 }.to_enum.map { |row| row[:external_ark_url] }.compact
  resources = self[:resource].filter(:external_ark_url => arks).each do |row|
    bad_records << "Resource #{row[:id]}: #{row[:title]} -- ARK: #{row[:external_ark_url]}"
  end

  unless bad_records.empty?
    raise "These resources have duplicate ARK URLs. Please disambiguate before proceeding \n #{bad_records.join("\n")}"
  end
end

Sequel.migration do
  up do
    check_for_ambiguous_ark_links

    # New ArkName columns
    alter_table(:ark_name) do
      add_column(:ark_value, String, :null => true)
      add_column(:is_current, Integer, :null => false, :default => 0)
      add_column(:is_external_url, Integer, :default => 0)
      add_column(:retired_at_epoch_ms, :Bignum, :null => false, :default => 0)
      add_column(:version_key, String, :null => true)
    end

    # Populate initial version_key
    self.transaction do
      self[:ark_name].update(:version_key => Digest::SHA256.hexdigest([AppConfig[:ark_naan], '', '', 'archivesspace_ark_minter'].to_json))
    end

    alter_table(:ark_name) do
      set_column_allow_null :version_key, false
    end

    # Migrate existing ARKs to the new layout
    self.transaction do

      delete_zombies

      now = (Time.now.to_f * 1000).to_i

      self[:ark_name].update(:is_current => 0, :retired_at_epoch_ms => Sequel.lit("#{now} - id"))

      self[:ark_name].select(:id).each do |row|
        self[:ark_name].filter(:id => row[:id]).update(:ark_value => "ark:/#{AppConfig[:ark_naan]}/#{row[:id]}")
      end

      # Migrate resources, moving external_ark_url into ark_name
      self[:ark_name]
        .filter(Sequel.~(:resource_id => nil))
        .group(:resource_id)
        .select(:resource_id, Sequel.as(Sequel.function(:max, :id), :max))
        .each do |row|

        external_ark_url = self[:resource].filter(:id => row.fetch(:resource_id))
                             .select(:external_ark_url)
                             .first
                             .fetch(:external_ark_url)

        if external_ark_url
          self[:ark_name]
            .filter(:resource_id => row.fetch(:resource_id),
                    :id => row[:max])
            .update(:is_current => 1,
                    :retired_at_epoch_ms => 0,
                    :is_external_url => 1,
                    :ark_value => external_ark_url)
        end
      end

      # Migrate archival objects, moving external_ark_url into ark_name
      self[:ark_name]
        .filter(Sequel.~(:archival_object_id => nil))
        .group(:archival_object_id)
        .select(:archival_object_id, Sequel.as(Sequel.function(:max, :id), :max))
        .each do |row|

        external_ark_url = self[:archival_object].filter(:id => row.fetch(:archival_object_id))
                             .select(:external_ark_url)
                             .first
                             .fetch(:external_ark_url)

        if external_ark_url
          self[:ark_name]
            .filter(:archival_object_id => row.fetch(:archival_object_id),
                    :id => row[:max])
            .update(:is_current => 1,
                    :is_external_url => 1,
                    :retired_at_epoch_ms => 0,
                    :ark_value => external_ark_url)
        end
      end
    end

    alter_table(:resource) do
      drop_column(:external_ark_url)
    end

    alter_table(:archival_object) do
      drop_column(:external_ark_url)
    end

    delete_zombies

    # We can now safely introduce foreign keys
    alter_table(:ark_name) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)

      add_unique_constraint([:archival_object_id, :is_current, :retired_at_epoch_ms], :name => "ark_name_ao_uniq")
      add_unique_constraint([:resource_id, :is_current, :retired_at_epoch_ms], :name => "ark_name_resource_uniq")
    end

    alter_table(:repository) do
      add_column(:ark_shoulder, String, :null => true)
    end

    create_table(:ark_uniq_check) do
      primary_key :id
      String :record_uri, :null => false
      String :value, :null => false
    end

    alter_table(:ark_uniq_check) do
      add_index([:value], :unique => true, :name => 'unique_ark_value')
      add_index([:record_uri], :unique => false, :name => 'record_uri_uniq_check_idx')
    end

    alter_table(:ark_name) do
      add_index([:ark_value, :resource_id], :name => 'ark_name_ark_value_res_idx')
      add_index([:ark_value, :archival_object_id], :name => 'ark_name_ark_value_ao_idx')
    end

    self.transaction do
      self[:ark_uniq_check].delete

      self[:resource].join(:ark_name, Sequel.qualify(:resource, :id) => Sequel.qualify(:ark_name, :resource_id))
        .select(:repo_id, :resource_id, :ark_value)
        .distinct
        .each do |row|

        self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/resources/#{row[:resource_id]}",
                                     :value => row[:ark_value].sub(/^.*?ark:/i, 'ark:'))
      end

      self[:archival_object].join(:ark_name, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:ark_name, :archival_object_id))
        .select(:repo_id, :archival_object_id, :ark_value)
        .distinct
        .each do |row|
        self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}",
                                     :value => row[:ark_value].sub(/^.*?ark:/i, 'ark:'))

      end
    end

    alter_table(:ark_name) do
      set_column_not_null(:ark_value)
    end

    [:resource_id, :archival_object_id].each do |fk_col|
      # Make sure every record has an is_current set
      currents = {}

      self[:ark_name]
        .filter(Sequel.~(fk_col => nil))
        .reverse(:id)
        .select(fk_col, :id)
        .each do |row|
        unless currents.include?(row[fk_col])
          currents[row[fk_col]] = row[:id]
        end
      end

      self[:ark_name]
        .filter(Sequel.~(fk_col => nil))
        .filter(:is_current => 1)
        .select(fk_col)
        .each do |row|
        currents.delete(row[fk_col])
      end

      currents.each do |resource_id, ark_name_id|
        self[:ark_name].filter(:id => ark_name_id).update(:is_current => 1)
      end
    end

    # reindex all records with an ARK
    now = Time.now
    [[:resource, :resource_id],
     [:archival_object, :archival_object_id]].each do |tbl, fk|
      self[tbl]
        .filter(:id => self[:ark_name].filter(Sequel.~(fk => nil)).select(fk))
        .update(:system_mtime => now)
    end

  end
end
