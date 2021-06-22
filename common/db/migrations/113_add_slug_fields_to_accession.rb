require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add slug fields to accession")
    alter_table(:accession) do
      add_column(:slug, String)
      add_column(:is_slug_auto, Integer, :default => 0)
    end
  end
end
