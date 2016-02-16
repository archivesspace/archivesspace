require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:top_container) do
      drop_column(:legacy_restricted) unless AppConfig[:plugins].include?("container_management") 
    end
  end
  
  down do
    alter_table(:top_container) do
      add_column(:legacy_restricted, Integer ) 
    end
  end


end
