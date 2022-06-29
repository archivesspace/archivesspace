require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts "Updating enum values for maintenance_status"
    add_values_to_enum("maintenance_status", ["deleted_merged"])
  end
end
