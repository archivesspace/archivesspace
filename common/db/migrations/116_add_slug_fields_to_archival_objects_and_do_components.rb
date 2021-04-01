require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add slug fields to archival object and digital object component")
    alter_table(:archival_object) do
      add_column(:slug, String)
      add_column(:is_slug_auto, Integer, :default => 0)
    end

    alter_table(:digital_object_component) do
      add_column(:slug, String)
      add_column(:is_slug_auto, Integer, :default => 0)
    end
  end
end
