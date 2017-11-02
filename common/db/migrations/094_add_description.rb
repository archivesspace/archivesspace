require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:repository) do
     TextField :description
    end
  end

  down do
    alter_table(:repository) do
      drop_column(:description)
    end
  end

end

