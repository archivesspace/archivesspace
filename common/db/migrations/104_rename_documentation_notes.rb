require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:assessment) do
      rename_column(:documentation_notes, :existing_description_notes)
    end
  end

  down do
  end

end

