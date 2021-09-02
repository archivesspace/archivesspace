require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      rename_column(:ark_prefix, :ark_shoulder)
    end
  end

  down do
  end
end
