require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:container_profile) do
      add_column(:stacking_limit, String, :null => true)
    end
  end


  down do
    alter_table(:container_profile) do
      drop_column(:stacking_limit)
    end
  end

end
