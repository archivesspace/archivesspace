require_relative 'utils'

Sequel.migration do

  up do

    create_table(:rde_template) do
      primary_key :id
      String :record_type, :null => false
      String :name, :null => false
      TextBlobField :order, :null => true
      TextBlobField :visible, :null => true
      TextBlobField :defaults, :null => true

      apply_mtime_columns
    end
  end

  down do
    drop_table(:rde_template)
  end

end
