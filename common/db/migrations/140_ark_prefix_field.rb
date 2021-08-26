require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      add_column(:ark_prefix, String, :null => true)
    end
  end

  down do
  end
end
