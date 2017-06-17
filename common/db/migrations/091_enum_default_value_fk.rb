require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:enumeration) do
      add_foreign_key([:default_value], :enumeration_value, :key => :id, :on_delete => :set_null)
    end
  end

  down do
    # nothing!
  end

end