require_relative 'utils'

Sequel.migration do
  up do

    alter_table(:accession) do
      add_column(:language_id, :integer, :null => true)
      add_column(:script_id, :integer, :null => true)
    end

  end
end
