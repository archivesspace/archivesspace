Sequel.migration do
  up do
    DB_TYPE = self.database_type
    create_table(:sessions) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false
      if DB_TYPE == :derby
        Clob :session_data, :null => true
      else
        Blob :session_data, :null => true
      end
    end
  end
  down do
    drop_table(:sessions)
  end
end
