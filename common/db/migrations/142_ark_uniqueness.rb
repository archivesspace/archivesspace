require_relative 'utils'

Sequel.migration do
  up do
    create_table(:ark_uniq_check) do
      primary_key :id
      String :record_uri, :null => false, :unique => true
      String :generated_value, :null => false, :unique => true
    end

    alter_table(:ark_name) do
      add_unique_constraint([:user_value], :name => "ark_user_value_uniq")
    end
  end
end
