require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:assessment) do
      add_column(:conservation_note, $db_type == :derby ? :clob : :text, :null => true)
    end

  end


  down do
  end

end

