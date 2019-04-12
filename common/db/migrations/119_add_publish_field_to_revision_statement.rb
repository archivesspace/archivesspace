require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add publish field to revision statement")
    alter_table(:revision_statement) do
      add_column(:publish, Integer, :default => 0)
    end

    self[:revision_statement].update(:publish => 0)
    self[:revision_statement].update(:system_mtime => Time.now)
  end
end
