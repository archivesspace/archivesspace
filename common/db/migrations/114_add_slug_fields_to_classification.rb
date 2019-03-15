require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:classification) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer, :default => 0)
    end
  end
end