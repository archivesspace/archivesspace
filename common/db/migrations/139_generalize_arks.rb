require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:ark_name) do
      add_column(:generated_value, String, :null => true)
      add_column(:user_value, String, :null => true)
      add_column(:is_current, Integer, :null => false, :default => 0)
      add_column(:retired_at_epoch_ms, :Bignum, :null => false, :default => 0)
    end

    self.transaction do
      now = (Time.now.to_f * 1000).to_i

      self[:ark_name].update(:is_current => 0, :retired_at_epoch_ms => Sequel.lit("#{now} - id"))

      self[:ark_name].select(:id).each do |row|
        self[:ark_name].filter(:id => row[:id]).update(:generated_value => "ark:/#{AppConfig[:ark_naan]}/#{row[:id]}")
      end

      # Migrate resources
      self[:ark_name]
        .filter(Sequel.~(:resource_id => nil))
        .group(:resource_id)
        .select(:resource_id, Sequel.as(Sequel.function(:max, :id), :max))
        .each do |row|

        user_value = self[:resource].filter(:id => row.fetch(:resource_id))
                       .select(:external_ark_url)
                       .first
                       .fetch(:external_ark_url)

        self[:ark_name]
          .filter(:resource_id => row.fetch(:resource_id),
                  :id => row[:max])
          .update(:is_current => 1,
                  :retired_at_epoch_ms => 0,
                  :user_value => user_value)
      end

      # Migrate archival objects
      self[:ark_name]
        .filter(Sequel.~(:archival_object_id => nil))
        .group(:archival_object_id)
        .select(:archival_object_id, Sequel.as(Sequel.function(:max, :id), :max))
        .each do |row|

        user_value = self[:archival_object].filter(:id => row.fetch(:archival_object_id))
                       .select(:external_ark_url)
                       .first
                       .fetch(:external_ark_url)

        self[:ark_name]
          .filter(:archival_object_id => row.fetch(:archival_object_id),
                  :id => row[:max])
          .update(:is_current => 1,
                  :retired_at_epoch_ms => 0,
                  :user_value => user_value)
      end
    end

    alter_table(:resource) do
      drop_column(:external_ark_url)
    end

    alter_table(:archival_object) do
      drop_column(:external_ark_url)
    end

    ## delete any unlinked arks
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

    alter_table(:ark_name) do
      add_unique_constraint([:archival_object_id, :is_current, :retired_at_epoch_ms], :name => "ark_name_ao_uniq")
      add_unique_constraint([:resource_id, :is_current, :retired_at_epoch_ms], :name => "ark_name_resource_uniq")

      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end

  end

  down do
  end
end
