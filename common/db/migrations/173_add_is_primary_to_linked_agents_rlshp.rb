require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add is_primary flag to linked_agents_rlshp")
    alter_table(:linked_agents_rlshp) do
      add_column(:is_primary, Integer, :null => true, :default => nil)
    end
  end
end
