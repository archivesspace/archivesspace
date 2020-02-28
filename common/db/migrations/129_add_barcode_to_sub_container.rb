require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add barcode fields to sub_container")
    alter_table(:sub_container) do
    	add_column(:barcode_2, String)
    end
  end
end
