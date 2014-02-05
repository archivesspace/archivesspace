require_relative 'utils'

Sequel.migration do

  up do
    [:resource, :archival_object, :digital_object, :digital_object_component].each do |table|
      alter_table(table) do
        add_column(:suppressed, :integer, :null => false, :default => 0)
      end
    end
  end


  down do
  end

end

