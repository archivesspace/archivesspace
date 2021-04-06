require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add slug fields to subject")
    alter_table(:subject) do
      add_column(:slug, String)
      add_column(:is_slug_auto, Integer, :default => 0)
    end
  end
end
