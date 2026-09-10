require_relative 'utils'

Sequel.migration do

  # hidden_at is the timestamp of when a records becase  unavailable (unpublished or suppressed)
  # it becomes nil when the record becomes available again. It is used to generate OAI-PMH tombstones for records that are hidden from harvesters.
  up do
    hidden_from_harvesters = Sequel.|(Sequel.~(:publish => 1),
                                      {:publish => nil},
                                      {:suppressed => 1})

    [:resource, :archival_object].each do |table|
      $stderr.puts("Add hidden_at to #{table}")

      alter_table(table) do
        add_column(:hidden_at, DateTime, :null => true, :default => nil)
        add_index(:hidden_at)
      end

      # Records that were already unavailable when this migration ran have no
      # record of when that happened, so seed them with system_mtime.
      self[table]
        .where(hidden_from_harvesters)
        .update(:hidden_at => Sequel[:system_mtime])
    end
  end

  down do
    [:resource, :archival_object].each do |table|
      alter_table(table) do
        drop_index(:hidden_at)
        drop_column(:hidden_at)
      end
    end
  end

end
