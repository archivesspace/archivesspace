require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:top_container) do
      drop_column(:legacy_restricted)     
    end
  end
  
  down do
    alter_table(:top_container) do
      add_colum(:legacy_restricted, Integer ) 
    end
  end


end
