Sequel.migration do

  up do

    alter_table(:assessment) do
      drop_column(:display_string)
    end

  end

  down do
  end

end
