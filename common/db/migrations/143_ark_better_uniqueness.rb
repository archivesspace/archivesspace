require_relative 'utils'

Sequel.migration do
  up do
    rename_table(:ark_uniq_check, :ark_uniq_check_replaced)

    create_table(:ark_uniq_check) do
      primary_key :id
      String :record_uri, :null => false
      String :generated_value, :null => false
    end

    alter_table(:ark_uniq_check) do
      add_index([:generated_value], :unique => true, :name => 'unique_generated_value')
      add_index([:record_uri], :unique => false, :name => 'record_uri_uniq_check_idx')
    end

    self.transaction do
      self[:ark_uniq_check_replaced].each do |row|
        self[:ark_uniq_check].insert(row)
      end
    end

    drop_table(:ark_uniq_check_replaced)
  end
end
