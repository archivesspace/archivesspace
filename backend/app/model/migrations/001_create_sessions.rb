Sequel.migration do
  up do
    create_table(:sessions) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false
      Blob :session_data, :null => true
    end
  end
  down do
    drop_table(:sessions)
  end
end
