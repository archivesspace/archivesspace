Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:created_for_collection, String, :null => true)
    end
  end


  down do
    # no going back
  end

end

