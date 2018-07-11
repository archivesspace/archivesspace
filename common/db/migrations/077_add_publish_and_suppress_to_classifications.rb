Sequel.migration do

  up do
    alter_table(:classification) do
      add_column(:publish, Integer, :default => 1)
      add_column(:suppressed, Integer, :default => 0)
    end

    alter_table(:classification_term) do
      add_column(:publish, Integer, :default => 1)
      add_column(:suppressed, Integer, :default => 0)
    end

  end


  down do
  end

end

