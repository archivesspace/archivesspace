require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:container) do
      set_column_allow_null :type_1_id 
      set_column_allow_null :indicator_1 
    end
  end
  
  down do
    # no taksies backsies
  end

end

