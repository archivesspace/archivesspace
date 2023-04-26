require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add is_representative flag to linked_agents_rlshp")
    alter_table(:linked_agents_rlshp) do
      add_column(:is_representative, Integer, :null => true, :default => nil)
    end
  end
end
