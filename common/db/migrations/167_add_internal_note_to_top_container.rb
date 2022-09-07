require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:internal_note, String)
    end
  end

  down do
  end

end
