require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:classification_rlshp) do
      add_column(:digital_object_id, Integer)
    end
  end

  down do
  end
end
