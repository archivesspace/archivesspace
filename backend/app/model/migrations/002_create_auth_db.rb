Sequel.migration do
  up do
    create_table(:auth_db) do
      primary_key :id
      String :username, :unique => true, :null => false
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
      String :pwhash, :null => false
    end
  end
  down do
    drop_table(:auth_db)
  end
end
