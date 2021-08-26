require_relative 'utils'

Sequel.migration do
  up do
    create_table(:ark_uniq_check) do
      primary_key :id
      String :record_uri, :null => false, :unique => true
      String :generated_value, :null => false, :unique => true
    end
  end
end
