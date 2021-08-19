require_relative 'utils'

Sequel.migration do
  up do

    alter_table(:lang_material) do
      add_column(:accession_id, :integer, :null => true)
      add_foreign_key([:accession_id], :accession, :key => :id)
    end

  end
end
