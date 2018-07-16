require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:repository) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer)
    end
  end
end