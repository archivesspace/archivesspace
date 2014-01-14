require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:collection_management) do
      add_column(:processing_started_date, Date, :null => true)
    end
  end


  down do
    alter_table(:collection_management) do
      drop_column(:processing_started_date)
    end
  end

end

