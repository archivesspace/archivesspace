require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add publish field to revision statement")
    alter_table(:revision_statement) do
      add_column(:publish, Integer, :default => 0)
    end
  end
end