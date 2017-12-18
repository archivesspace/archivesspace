require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:enumeration) do
      add_foreign_key([:default_value], 
                      :enumeration_value, :key => :id,
                      :name => "enumeration_default_value_fk",  
                      :on_delete => :set_null)
    end
  end

  down do
     alter_table(:enumeration) { drop_foreign_key(:default_value)  }
  end

end
