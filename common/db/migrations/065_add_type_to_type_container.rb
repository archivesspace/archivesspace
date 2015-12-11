require_relative 'utils'

Sequel.migration do

	up do
    alter_table(:top_container) do
      add_column( :type_id, :integer,  :null => true ) 
      add_foreign_key([:type_id], :enumeration_value, :key => :id, :name => 'top_container_type_fk')
    end
  end

  down do
  end

end
